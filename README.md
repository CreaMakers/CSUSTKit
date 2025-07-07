# CSUST API Swift

一个用于访问长沙理工大学各个系统 API 的 Swift 库，支持教务系统、慕课平台、校园卡系统和 SSO 统一认证。

## 项目结构

### 🔐 SSO (单点登录)

- **SSOHelper**: 统一身份认证服务，支持登录验证和会话管理
- **功能**: 自动处理验证码检测、用户登录、会话保持

### 📚 Education (教务系统)

- **EduHelper**: 教务管理核心模块
- **服务模块**:
  - AuthService: 身份验证
  - CourseService: 课程管理
  - ExamService: 考试信息
  - ProfileService: 个人档案
  - SemesterService: 学期管理
- **功能**: 课程查询、成绩查询、考试安排、学期信息等

### 🎓 Mooc (慕课平台)

- **MoocHelper**: 在线学习平台接口
- **功能**: 用户资料获取、课程列表、学习进度等

### 💳 CampusCard (校园卡)

- **CampusCardHelper**: 校园一卡通服务
- **功能**: 楼栋信息查询、电费查询等校园生活服务

## 快速开始

1. 配置环境变量

```bash
echo "CSUST_USERNAME=你的学号" > .env
echo "CSUST_PASSWORD=你的密码" >> .env
```

2. 运行项目

```bash
swift run
```

## 使用示例

```swift
// SSO登录
let ssoHelper = SSOHelper()
try await ssoHelper.login(username: "your_username", password: "your_password")

// 获取用户信息
let user = try await ssoHelper.getLoginUser()

// 访问慕课平台
let moocHelper = MoocHelper(session: try await ssoHelper.loginToMooc())
let profile = try await moocHelper.getProfile()
let courses = try await moocHelper.getCourses()
```

## 许可证

本项目仅供学习和研究使用，请遵守学校相关规定。
