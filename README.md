# CSUSTKit

一个用于访问长沙理工大学各个系统 API 的 Swift 库，支持教务系统、慕课平台、校园卡系统和 SSO 统一认证。

## 特性

- 🔐 **SSO**: 统一身份认证服务
- 📚 **Education**: 教务系统（课程、成绩、考试等）
- 🎓 **Mooc**: 慕课平台接口
- 💳 **CampusCard**: 校园一卡通服务

## 安装

### Swift Package Manager

在你的 `Package.swift` 文件中添加依赖：

```swift
dependencies: [
    .package(url: "https://github.com/zHElEARN/CSUSTKit.git", from: "1.0.0")
]
```

### Xcode

1. 打开你的 Xcode 项目
2. 选择 **File** → **Add Package Dependencies**
3. 输入仓库 URL: `https://github.com/zHElEARN/CSUSTKit.git`

## 使用示例

```swift
import CSUSTKit

// SSO 登录
let ssoHelper = SSOHelper()
try await ssoHelper.login(username: "your_username", password: "your_password")

// 获取用户信息
let user = try await ssoHelper.getLoginUser()

// 访问慕课平台
let moocHelper = MoocHelper(session: try await ssoHelper.loginToMooc())
let profile = try await moocHelper.getProfile()

// 教务系统操作
let eduHelper = EduHelper(session: try await ssoHelper.loginToEducation())
let courses = try await eduHelper.getCourses()
```

## 许可证

本项目仅供学习和研究使用，请遵守学校相关规定。
