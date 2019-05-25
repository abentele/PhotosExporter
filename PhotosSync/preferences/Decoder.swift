/*
 * Copyright 2017-2018 Seznam.cz, a.s.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/*
 * Author: Daniel Bilik (daniel.bilik@firma.seznam.cz)
 */

import Foundation

public enum UniYAMLError: Error {
	case error(detail: String)
}

public struct UniYAML {

	static public func decode(_ stream: String) throws -> YAML {
		var document = [YAML]()
		var stack = [YAML]()
		// TODO var anchors = [String: YAML]()
		var lines = 1
		var index = stream.startIndex
		var flow = [Character]()
		var token: String?
		while index < stream.endIndex {
			do {
				let indent: Int = parseIndent(stream, index: &index)
				if token == nil {
					token = try parseToken(stream, index: &index, to: ":", inFlow: flow.last)
				}
				guard let t = token?.trimmingCharacters(in: CharacterSet(charactersIn: " ")), !t.isEmpty else {
					if index < stream.endIndex {
						switch stream[index] {
						case "\r", "\n", "\u{85}":
							lines += 1
						case ":":
							throw UniYAMLError.error(detail: "unexpected colon")
						default:
							break
						}
						index = stream.index(after: index)
					}
					continue
				}
				var key: String?
				var anchor: String?
				var tag: String?
				var value: String?
				switch t {
				case "---", "...":
					if stack.count > 0 {
						try foldStack(&stack, toIndent: -1)
						document.append(stack.first!)
						stack.removeAll()
					}
					token = nil
					continue
				case "#":
					if let border = stream.rangeOfCharacter(from: CharacterSet(charactersIn: "\r\n\u{85}"), range: Range(uncheckedBounds: (index, stream.endIndex))) {
						index = border.lowerBound
					} else {
						index = stream.endIndex
					}
					token = nil
					continue
				case "{":
					if stack.count == 0 {
						guard indent == 0 else {
							throw UniYAMLError.error(detail: "unexpected indentation")
						}
						stack.append(YAML(indent: -1, type: .dictionary, key: nil, tag: nil, value: [String: YAML]()))
					}
					let last = stack.count - 1
					if stack[last].type == .pending {
						stack[last].type = .dictionary
						stack[last].value = [String: YAML]()
					}
					flow.append("}")
					token = nil
					continue
				case "[":
					if stack.count == 0 {
						guard indent == 0 else {
							throw UniYAMLError.error(detail: "unexpected indentation")
						}
						stack.append(YAML(indent: -1, type: .array, key: nil, tag: nil, value: [YAML]()))
					}
					let last = stack.count - 1
					if stack[last].type == .pending {
						stack[last].type = .array
						stack[last].value = [YAML]()
					}
					flow.append("]")
					token = nil
					continue
				case "}", "]":
					try foldStack(&stack, toIndent: nil)
					guard let brace = flow.popLast(), t[t.startIndex] == brace else {
						throw UniYAMLError.error(detail: "unexpected closing brace")
					}
					token = nil
					continue
				case "-":
					if stack.count == 0 {
						guard indent == 0 else {
							throw UniYAMLError.error(detail: "unexpected indentation")
						}
						stack.append(YAML(indent: -1, type: .array, key: nil, tag: nil, value: [YAML]()))
					}
					let last = stack.count - 1
					if stack[last].type == .pending {
						stack[last].type = .array
						stack[last].value = [YAML]()
						if flow.isEmpty, indent < stack[last].indent {
							throw UniYAMLError.error(detail: "unexpected indentation")
						}
					} else if flow.isEmpty, stack[last].indent > indent {
						try foldStack(&stack, toIndent: indent + 1)
					}
					token = try parseToken(stream, index: &index, honorDash: false, inFlow: flow.last)
					guard let tt = token?.trimmingCharacters(in: CharacterSet(charactersIn: " ")), !tt.isEmpty else {
						stack.append(YAML(indent: indent + 1, type: .pending, key: nil, tag: nil, value: nil))
						continue
					}
					switch tt {
					case "#":
						continue
					case "{", "[":
						stack.append(YAML(indent: indent, type: .pending, key: nil, tag: nil, value: nil))
						continue
					case "}", "]":
						throw UniYAMLError.error(detail: "unexpected closing brace")
					case "|", ">":
						value = try parseMultilineValue(stream, index: &index, line: &lines, indent: indent, folded: (tt == ">"))
					default:
						(anchor, tag, value) = parseValue(tt)
					}
					token = nil
				default:
					guard index < stream.endIndex else {
						throw UniYAMLError.error(detail: "unexpected stream end")
					}
					if stream[index] == ":" {
						if stack.count == 0 {
							guard indent == 0 else {
								throw UniYAMLError.error(detail: "unexpected indentation")
							}
							stack.append(YAML(indent: -1, type: .dictionary, key: nil, tag: nil, value: [String: YAML]()))
						}
						let last = stack.count - 1
						if stack[last].type == .pending {
							if flow.isEmpty, indent <= stack[last].indent {
								stack[last].type = .array
								stack[last].value = [YAML]()
								try foldStack(&stack, toIndent: indent)
							} else {
								stack[last].type = .dictionary
								stack[last].value = [String: YAML]()
							}
						} else if flow.isEmpty, stack[last].indent >= indent {
							try foldStack(&stack, toIndent: indent)
						}
						key = dequote(t)
						index = stream.index(after: index)
						token = try parseToken(stream, index: &index, honorDash: false, inFlow: flow.last)
						if let tt = token?.trimmingCharacters(in: CharacterSet(charactersIn: " ")), !tt.isEmpty {
							switch tt {
							case "#":
								continue
							case "{", "[":
								stack.append(YAML(indent: indent, type: .pending, key: key, tag: nil, value: nil))
								continue
							case "}", "]":
								throw UniYAMLError.error(detail: "unexpected closing brace")
							case "|", ">":
								value = try parseMultilineValue(stream, index: &index, line: &lines, indent: indent, folded: (tt == ">"))
							default:
								(anchor, tag, value) = parseValue(tt)
							}
						}
					} else if let f = flow.last, f == "]" {
						(anchor, tag, value) = parseValue(t)
					} else if flow.isEmpty, stack.last?.type == .pending {
						let last = stack.count - 1
						guard indent > stack[last].indent else {
							throw UniYAMLError.error(detail: "unexpected indentation")
						}
						index = stream.index(index, offsetBy: -(indent + t.count + 1))
						lines -= 1
						stack[last].type = .string
						stack[last].value = try parseMultilineValue(stream, index: &index, line: &lines, indent: stack[last].indent, folded: true)
					} else {
						throw UniYAMLError.error(detail: "unexpected value")
					}
					token = nil
				}

				//print("DEBUG\tindent: \(indent), key: \(key), value: \(value)")

				var last = stack.count - 1
				if let k = key {
					if let v = value {
						guard let dictionary = stack[last].value as? [String: YAML] else {
							throw UniYAMLError.error(detail: "value type mismatch")
						}
						if flow.isEmpty, let first = dictionary.values.first?.indent, indent != first {
							throw UniYAMLError.error(detail: "indentation mismatch")
						}
						var complete = v
						if flow.isEmpty, index < stream.endIndex, indent < checkIndent(stream, index: stream.index(after: index)) {
							// NOTE: handle the case where a value for a key spans to next line(s)
							let tail = try parseMultilineValue(stream, index: &index, line: &lines, indent: indent, folded: true)
							complete += " \(tail)"
						}
						var d = dictionary
						d[k] = YAML(indent: indent, type: .string, key: k, tag: tag, value: complete)
						stack[last].value = d
					} else {
						stack.append(YAML(indent: indent, type: .pending, key: k, tag: nil, value: nil))
					}
				} else if let v = value {
					guard let array = stack[last].value as? [YAML] else {
						throw UniYAMLError.error(detail: "value type mismatch")
					}
					var a = array
					if flow.isEmpty, let previous = array.last {
						if previous.indent < indent {
							throw UniYAMLError.error(detail: "indentation mismatch")
						} else if previous.indent > indent {
							try foldStack(&stack, toIndent: indent + 1)
							last = stack.count - 1
							guard let array2 = stack[last].value as? [YAML] else {
								throw UniYAMLError.error(detail: "value type mismatch")
							}
							a = array2
						}
					}
					a.append(YAML(indent: indent, type: .string, key: nil, tag: tag, value: v))
					stack[last].value = a
				}
			} catch UniYAMLError.error(let detail) {
				throw UniYAMLError.error(detail: "\(detail) at line \(lines)")
			}
		}
		if stack.count > 0 {
			guard flow.isEmpty else {
				throw UniYAMLError.error(detail: "unclosed brace")
			}
			try foldStack(&stack, toIndent: -1)
			document.append(stack.first!)
		}
		var result: YAML
		switch document.count {
		case 0:
			result = YAML(indent: 0, type: .empty, key: nil, tag: nil, value: nil)
		case 1:
			result = document[0]
		default:
			result = YAML(indent: 0, type: .array, key: nil, tag: nil, value: document)
		}
		return result
	}

	static private func checkIndent(_ stream: String, index: String.Index) -> Int {
		var indent = 0
		var idx = index
		while idx < stream.endIndex {
			guard stream[idx] == " " else {
				break
			}
			idx = stream.index(after: idx)
			indent += 1
		}
		return indent
	}

	static private func parseIndent(_ stream: String, index: inout String.Index) -> Int {
		let indent = checkIndent(stream, index: index)
		index = stream.index(index, offsetBy: indent)
		return indent
	}

	static private func parseToken(_ stream: String, index: inout String.Index, to: String = "", honorDash: Bool = true, inFlow: Character? = nil) throws -> String? {
		guard index < stream.endIndex else {
			return nil
		}
		_ = parseIndent(stream, index: &index)
		var search = Range(uncheckedBounds: (index, stream.endIndex))
		var location = search
		var fragments = ""
		switch stream[index] {
		case "\r", "\n", "\u{85}":
			return nil
		case "#", "{", "}", "[", "]", "|", ">":
			let i = stream.index(after: index)
			location = Range(uncheckedBounds: (index, i))
			index = i
		case "-" where (honorDash && inFlow == nil):
			guard let border = stream.rangeOfCharacter(from: CharacterSet(charactersIn: " \r\n\u{85}"), range: search) else {
				throw UniYAMLError.error(detail: "unexpected value")
			}
			location = Range(uncheckedBounds: (index, border.lowerBound))
			index = location.upperBound
		case "'":
			var i = stream.index(after: index)
			while i < stream.endIndex {
				search = Range(uncheckedBounds: (i, stream.endIndex))
				guard let ii = stream.rangeOfCharacter(from: CharacterSet(charactersIn: "'"), range: search) else {
					throw UniYAMLError.error(detail: "unclosed quotes")
				}
				guard ii.lowerBound < stream.endIndex, stream[ii] == "'" else {
					throw UniYAMLError.error(detail: "unclosed quotes")
				}
				// NOTE: bad ugly "fragments" hack to correctly parse notation like this:
				//       key: 'this ''fragmented'' value'
				if ii.upperBound < stream.endIndex, stream[ii.upperBound] == "'" {
					fragments.append(String(stream[i..<ii.upperBound]))
					i = stream.index(after: ii.upperBound)
					continue
				}
				if fragments.isEmpty {
					location = Range(uncheckedBounds: (index, stream.index(after: ii.lowerBound)))
					i = ii.upperBound
				} else {
					fragments.append(String(stream[i..<ii.lowerBound]))
					i = (ii.upperBound < stream.endIndex) ? stream.index(after: ii.upperBound):stream.endIndex
				}
				break
			}
			index = i
		case "\"":
			var i = stream.index(after: index)
			while i < stream.endIndex {
				search = Range(uncheckedBounds: (i, stream.endIndex))
				guard let ii = stream.rangeOfCharacter(from: CharacterSet(charactersIn: "\""), range: search) else {
					throw UniYAMLError.error(detail: "unclosed quotes")
				}
				guard ii.lowerBound < stream.endIndex, stream[ii] == "\"" else {
					throw UniYAMLError.error(detail: "unclosed quotes")
				}
				location = Range(uncheckedBounds: (index, stream.index(after: ii.lowerBound)))
				i = ii.upperBound
				if stream[stream.index(before: ii.lowerBound)] != "\\" {
					break
				}
			}
			index = i
		default:
			let stop = (inFlow != nil) ? "\(to),]}":"\(to)\r\n\u{85}"
			if let border = stream.rangeOfCharacter(from: CharacterSet(charactersIn: stop), range: search) {
				location = Range(uncheckedBounds: (index, border.lowerBound))
			}
			index = location.upperBound
		}
		_ = parseIndent(stream, index: &index)
		// NOTE: echoes of bad ugly hack, see the comment above
		if !fragments.isEmpty {
			return fragments
		}
		return (location.lowerBound == location.upperBound) ? nil:String(stream[location])
	}

	static private func parseValue(_ string: String?) -> (String?, String?, String?) {
		let anchor: String? = nil // TODO
		let tag: String? = nil // TODO
		let value = dequote(string)
		return (anchor, tag, value)
	}

	static private func parseMultilineValue(_ stream: String, index: inout String.Index, line: inout Int, indent: Int, folded: Bool) throws -> String {
		guard index < stream.endIndex else {
			throw UniYAMLError.error(detail: "unexpected stream end")
		}
		guard stream[index] == "\r" || stream[index] == "\n" || stream[index] == "\u{85}" else {
			throw UniYAMLError.error(detail: "unexpected trailing characters")
		}
		index = stream.index(after: index)
		line += 1
		var value: String = ""
		var glue: Character = " "
		var block: Int = -1
		while index < stream.endIndex {
			let i = checkIndent(stream, index: index)
			guard i > indent else {
				break
			}
			if block == -1 {
				block = i
			}
			guard i >= block else {
				throw UniYAMLError.error(detail: "unexpected indentation")
			}
			index = stream.index(index, offsetBy: i)
			var location = Range(uncheckedBounds: (index, stream.endIndex))
			if let border = stream.rangeOfCharacter(from: CharacterSet(charactersIn: "\r\n\u{85}"), range: location) {
				location = Range(uncheckedBounds: (index, border.lowerBound))
				glue = (folded) ? " ":stream[border.lowerBound]
			}
			index = stream.index(after: location.upperBound)
			line += 1
			if !value.isEmpty {
				value += "\(glue)"
			}
			value += stream[location]
		}
		guard !value.isEmpty else {
			throw UniYAMLError.error(detail: "missing value")
		}
		return value
	}

	static private func dequote(_ string: String?) -> String? {
		guard let ss = string else {
			return nil
		}
		let s = ss.replacingOccurrences(of: "\r", with: "").replacingOccurrences(of: "\n", with: "").replacingOccurrences(of: "\u{85}", with: "")
		if s.hasPrefix("'"), s.hasSuffix("'") {
			return String(s[s.index(after: s.startIndex)..<s.index(before: s.endIndex)])
		} else if s.hasPrefix("\""), s.hasSuffix("\"") {
			return String(s[s.index(after: s.startIndex)..<s.index(before: s.endIndex)]
					.replacingOccurrences(of: "\\\\", with: "_backslash_holder_") // XXX: bad ugly hack
					.replacingOccurrences(of: "\\0", with: "\0")
					.replacingOccurrences(of: "\\t", with: "\t")
					.replacingOccurrences(of: "\\n", with: "\n")
					.replacingOccurrences(of: "\\r", with: "\r")
					.replacingOccurrences(of: "\\\"", with: "\"")
					.replacingOccurrences(of: "\\'", with: "'")
					.replacingOccurrences(of: "_backslash_holder_", with: "\\"))
		}
		return s
	}

	static private func foldStack(_ stack: inout [YAML], toIndent: Int? = nil) throws -> Void {
		while stack.count > 1 {
			if let indent = toIndent, stack.last!.indent < indent {
				break
			}
			let last = stack.popLast()
			let idx = stack.count - 1
			switch stack[idx].type {
			case .array:
				guard let array = stack[idx].value as? [YAML] else {
					throw UniYAMLError.error(detail: "array value mismatch")
				}
				var a = array
				a.append(last!)
				stack[idx].value = a
			case .dictionary:
				guard let key = last!.key, let dictionary = stack[idx].value as? [String: YAML] else {
					throw UniYAMLError.error(detail: "dictionary value mismatch")
				}
				var d = dictionary
				d[key] = last!
				stack[idx].value = d
			default:
				throw UniYAMLError.error(detail: "unexpected value")
			}
			if let indent = toIndent, last!.indent > indent {
				continue
			}
			break
		}
	}

}
