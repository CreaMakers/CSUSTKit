func handleAsyncOperation(_ operation: () async throws -> Void) async {
    do {
        try await operation()
    } catch {
        print("操作失败: \(error)")
    }
}

func prompt(_ message: String) -> String {
    print("\(message)：", terminator: " ")
    return readLine()?.trimmed() ?? ""
}

func promptNonEmpty(_ message: String) -> String {
    while true {
        let input = prompt(message)
        if !input.isEmpty {
            return input
        }
        print("输入不能为空，请重新输入。")
    }
}

func promptInt(_ message: String, validRange: ClosedRange<Int>) -> Int {
    while true {
        let input = prompt(message)
        if let value = Int(input), validRange.contains(value) {
            return value
        }
        print("输入无效，请输入 \(validRange.lowerBound)-\(validRange.upperBound) 之间的整数。")
    }
}

func promptSelection<T>(
    title: String,
    options: [(String, String)],
    mapper: (String) -> T?
) -> T {
    while true {
        print("")
        print(title)
        for option in options {
            print("\(option.0). \(option.1)")
        }
        let input = prompt("请选择")
        if let value = mapper(input) {
            return value
        }
        print("输入无效，请重新选择。")
    }
}

func selectIndexedItem<T>(
    title: String,
    items: [T],
    display: (T) -> String
) -> T? {
    guard !items.isEmpty else {
        return nil
    }

    while true {
        print("")
        print(title)
        for (index, item) in items.enumerated() {
            print("\(index + 1). \(display(item))")
        }
        print("0. 返回")

        let input = prompt("请选择")
        if input == "0" {
            return nil
        }
        if let index = Int(input), items.indices.contains(index - 1) {
            return items[index - 1]
        }
        print("输入无效，请重新选择。")
    }
}

extension String {
    fileprivate func trimmed() -> String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
