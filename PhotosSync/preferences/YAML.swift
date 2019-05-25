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

public enum YAMLType: String {
	case pending
	case empty
	case string
	case integer
	case double
	case array
	case dictionary
}

public struct YAML {
	let indent: Int
	var type: YAMLType
	let key: String?
	let tag: String?
	var value: Any?
	public var count: Int? {
		if type == .array, let array = value as? [YAML] {
			return array.count
		} else if type == .dictionary, let dictionary = value as? [String: YAML] {
			return dictionary.keys.count
		}
		return nil
	}
	public var keys: [String]? {
		if type == .dictionary, let dictionary = value as? [String: YAML] {
			return dictionary.keys.map { member in return member }
		}
		return nil
	}
	public var string: String? {
		return (type == .string) ? (value as? String):nil
	}
	public var int: Int? {
		if type == .integer, let i = value as? Int {
			return i
		} else if type == .string, let i = value as? String {
			return Int(i)
		}
		return nil
	}
	public var uint: UInt? {
		if type == .integer, let i = value as? Int {
			return UInt(i)
		} else if type == .string, let i = value as? String, let u = UInt(i) {
			return u
		}
		return nil
	}
	public var double: Double? {
		if type == .double, let d = value as? Double {
			return d
		} else if type == .string, let i = value as? String {
			return Double(i)
		}
		return nil
	}
	public var bool: Bool? {
		var s: String
		if type == .string {
			s = value as! String
		} else if type == .integer {
			s = "\(value as! Int)"
		} else {
			return nil
		}
		switch s.lowercased() {
		case "0", "off", "false", "no":
			return false
		case "1", "on", "true", "yes":
			return true
		default:
			return nil
		}
	}
	public var array: [YAML]? {
		return (type == .array) ? (value as? [YAML]):nil
	}
	public var dictionary: [String: YAML]? {
		return (type == .dictionary) ? (value as? [String: YAML]):nil
	}
	public var first: YAML? {
		guard type == .array, let array = value as? [YAML] else {
			return nil
		}
		return array.first
	}
	public var last: YAML? {
		guard type == .array, let array = value as? [YAML] else {
			return nil
		}
		return array.last
	}
	public subscript(index: Int) -> YAML? {
		get {
			guard type == .array, let array = value as? [YAML] else {
				return nil
			}
			return array[index]
		}
		set(newValue) {
			if let v = newValue, type == .array, var array = value as? [YAML] {
				array[index] = v
				value = array
			}
		}
	}
	public subscript(key: String) -> YAML? {
		get {
			guard type == .dictionary, let dictionary = value as? [String: YAML] else {
				return nil
			}
			return dictionary[key]
		}
		set(newValue) {
			if let v = newValue, type == .dictionary, var dictionary = value as? [String: YAML] {
				dictionary[key] = YAML(indent: 0, type: v.type, key: key, tag: nil, value: v.value)
				value = dictionary
			}
		}
	}
	public init(indent: Int, type: YAMLType, key: String?, tag: String?, value: Any?) {
		self.indent = indent
		self.type = type
		self.value = value
		self.key = key
		self.tag = tag
	}
	public init(_ string: String) {
		indent = 0
		type = .string
		value = string
		key = nil
		tag = nil
	}
	public init(_ int: Int) {
		indent = 0
		type = .integer
		value = int
		key = nil
		tag = nil
	}
	public init(_ uint: UInt) {
		indent = 0
		type = .integer
		value = Int(uint)
		key = nil
		tag = nil
	}
	public init(_ double: Double) {
		indent = 0
		type = .double
		value = double
		key = nil
		tag = nil
	}
	public init?(_ array: [Any]) {
		var obj = [YAML]()
		for member in array {
			if let s = member as? String {
				obj.append(YAML(s))
			} else if let i = member as? Int {
				obj.append(YAML(i))
			} else if let u = member as? UInt {
				obj.append(YAML(u))
			} else if let d = member as? Double {
				obj.append(YAML(d))
			} else if let y = member as? YAML {
				obj.append(y)
			} else {
				return nil
			}
		}
		indent = 0
		type = .array
		value = obj
		key = nil
		tag = nil
	}
	public init?(_ dictionary: [String: Any]) {
		var obj = [String: YAML]()
		for (k, v) in dictionary {
			if let s = v as? String {
				obj[k] = YAML(s)
			} else if let i = v as? Int {
				obj[k] = YAML(i)
			} else if let u = v as? UInt {
				obj[k] = YAML(u)
			} else if let d = v as? Double {
				obj[k] = YAML(d)
			} else if let y = v as? YAML {
				obj[k] = y
			} else {
				return nil
			}
			obj[k]!.key = k
		}
		indent = 0
		type = .dictionary
		value = obj
		key = nil
		tag = nil
	}
}
