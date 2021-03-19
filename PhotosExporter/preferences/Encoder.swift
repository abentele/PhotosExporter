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
 * Authors:
 * Daniel Bilik (daniel.bilik@firma.seznam.cz)
 * Tomas Zabojnik (tomas.zabojnik@firma.seznam.cz)
 */

import Foundation

public enum UniYAMLNotation: String {
	case json, yaml
}

extension UniYAML {
	private enum TokenType: String {
		case document, raw, emptyArray, emptyDict,
			arrayOpen, arrayClose, arraySeparator,
			dictOpen, dictClose, dictKey, dictSeparator,
			stream
	}

	private struct Token {
		let type: TokenType
		let data: Any?
		init(_ type: TokenType, data: Any?=nil) {
			self.type = type
			self.data = data
		}
	}

	static private func escape(_ input: String) -> String {
		return input.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"").replacingOccurrences(of: "\t", with: "\\t").replacingOccurrences(of: "\n", with: "\\n").replacingOccurrences(of: "\r", with: "\\r")
	}

	static private func escapeYamlString(_ input: String, isKey: Bool=false) -> String {
		var forbiddenChars = "[]{}<>-:=&\n%,@?*#|!\"'`"
		if isKey {
			forbiddenChars += " \t\r"
		}
		let forbidden = CharacterSet(charactersIn: forbiddenChars)
		if input.rangeOfCharacter(from: forbidden) != nil {
			return "\"" + UniYAML.escape(input) + "\"";
		}
		return input;
	}

	static public func encode(_ object: Any, with notation: UniYAMLNotation = .json) throws -> String {
		var stream = ""
		var indent: Int = 0
		var stack = [Token]()
		stack.append(Token(.raw, data: object))
		var prevToken: TokenType = .document
		while stack.count > 0 {
			let current = stack.remove(at: 0)
			if current.type == .raw {
				if let obj = current.data as? Int {
					stack.insert(Token(.stream, data: "\(obj)"), at: 0)
				} else if let obj = current.data as? Double {
					stack.insert(Token(.stream, data: "\(obj)"), at: 0)
				} else if let obj = current.data as? String {
					var escaped: String
					if notation == .yaml {
						escaped = escapeYamlString(obj)
					} else {
						escaped = "\"" + escape(obj) + "\""
					}
					stack.insert(Token(.stream, data: escaped), at: 0)
				} else if let obj = current.data as? [Any], obj.count == 0 {
					stack.insert(Token(.emptyArray), at: 0)
				} else if let obj = current.data as? [Any] {
					stack.insert(Token(.arrayOpen, data: indent), at: 0)
					var i = 1
					for item in obj {
						if (i > 1) {
							stack.insert(Token(.arraySeparator, data: indent), at: i)
							i += 1
						}
						stack.insert(Token(.raw, data: item), at: i)
						i += 1
					}
					stack.insert(Token(.arrayClose), at: i)
				} else if let obj = current.data as? [String: Any], obj.count == 0 {
					stack.insert(Token(.emptyDict), at: 0)
				} else if let obj = current.data as? [String: Any] {
					stack.insert(Token(.dictOpen, data: indent), at: 0)
					var i = 1
					for (key, value) in obj {
						if (i > 1) {
							stack.insert(Token(.dictSeparator, data: indent), at: i)
							i += 1
						}
						stack.insert(Token(.dictKey, data:key), at: i)
						stack.insert(Token(.raw, data: value), at: i+1)
						i += 2
					}
					stack.insert(Token(.dictClose), at: i)
				} else if let obj = current.data as? YAML, obj.value != nil {
					stack.insert(Token(.raw, data: obj.value), at: 0)
				} else {
					throw UniYAMLError.error(detail: "unsupported type")
				}
			} else {
				if current.type == .arrayOpen || current.type == .dictOpen {
					indent += 1
				} else if current.type == .arrayClose || current.type == .dictClose {
					indent -= 1
				}

				if notation == .yaml {
					stream += encodeYaml(current, prevToken)
				} else {
					stream += encodeJson(current)
				}
				prevToken = current.type
			}
		}
		return stream
	}

	static private func encodeJson(_ token: Token) -> String {
		let dict: [TokenType: String] = [
			.emptyArray:     "[]",
			.arrayOpen:      "[",
			.arrayClose:     "]",
			.arraySeparator: ",",
			.emptyDict:      "{}",
			.dictOpen:       "{",
			.dictClose:      "}",
			.dictSeparator:  ",",
		]

		if let val = dict[token.type] {
			return val
		} else if token.type == .dictKey {
			let key = token.data as! String
			return "\"" + escape(key) + "\":"
		} else if token.type == .stream {
			let str = token.data as! String
			return str
		}

		return ""
	}

	static private func encodeYaml(_ token: Token, _ context: TokenType) -> String {
		var result: String = ""
		switch token.type {
			case .emptyArray:
				return "[]\n"
			case .arrayOpen:
				if context == .dictKey {
					let indent = token.data as! Int
					result = "\n" + String(repeating: " ", count: indent*2)
				}
				result += "- "
			case .arraySeparator:
				let indent = token.data as! Int
				result = String(repeating: " ", count: indent*2) + "- "
			case .emptyDict:
				result = "{}\n"
			case .dictKey:
				let key = token.data as! String
				result = escapeYamlString(key, isKey: true) + ": "
			case .dictOpen:
				if context == .dictKey {
					let indent = token.data as! Int
					result = "\n" + String(repeating: " ", count: indent*2)
				}
			case .dictSeparator:
				let indent = token.data as! Int
				result = String(repeating: " ", count: indent*2)
			case .stream:
				let str = token.data as! String
				result = str + "\n"
			default:
				break
		}
		return result
	}
}
