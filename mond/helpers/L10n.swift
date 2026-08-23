//
//  L10n.swift
//  mond
//
//  In-app language switching (English / 中文) for mond-CN.
//

import SwiftUI
import Combine

/// Supported interface languages.
enum AppLanguage: String, CaseIterable, Identifiable {
    case english = "en"
    case chinese = "zh-Hans"

    var id: String { rawValue }

    /// Shown inside the language picker, always written in its own language.
    var display_name: String {
        switch self {
        case .english: return "English"
        case .chinese: return "中文"
        }
    }
}

/// Provides localized strings and drives UI updates when the language changes.
///
/// English strings in the codebase are the source of truth: in English mode
/// `t(_:)` returns the key unchanged, while in Chinese mode it looks up the
/// Chinese translation and falls back to English when a string is missing.
final class L10n: ObservableObject {
    static let shared = L10n()

    @AppStorage("app_language") private var stored_language = AppLanguage.english.rawValue

    @Published var language: AppLanguage = .english

    private init() {
        language = AppLanguage(rawValue: stored_language) ?? .english
    }

    /// Applies and persists a language change.
    func set(_ new_language: AppLanguage) {
        guard new_language != language else { return }
        language = new_language
        stored_language = new_language.rawValue
    }

    /// A SwiftUI binding that keeps pickers and the persisted value in sync.
    var language_binding: Binding<AppLanguage> {
        Binding(
            get: { self.language },
            set: { self.set($0) }
        )
    }

    /// Returns the localized string for `key`, substituting `args`.
    func t(_ key: String, _ args: CVarArg...) -> String {
        let value = language == .chinese ? (translations[key] ?? key) : key
        if args.isEmpty { return value }
        return String(format: value, arguments: args)
    }

    private let translations: [String: String] = [
        // MARK: Home (ContentView)
        "Language": "语言",
        "Choose the language used by the app.": "选择本应用使用的语言。",
        "Logs": "日志",
        "Tweaks": "插件",
        "Only MobileGestalt is available when method is set to cmg.": "当方法设置为 cmg 时，只有 MobileGestalt 可用。",
        "Advanced": "高级",
        "CacheExtra Fields": "CacheExtra 字段",
        "Only use these Tweaks if you know what you're doing.\nYou could break something irreversibly.": "只有在你明确知道自己在做什么时，才使用这些插件。\n某些操作可能造成不可逆的损坏。",

        // MARK: Settings (SettingsView)
        "Method": "方法",
        "Run Exploit": "运行 Exploit",
        "**CMG:** Supports iOS 27.0 b1 - b4. Only MobileGestalt will work with this method. Only use this when bad_query isnt working for you.": "**CMG：** 支持 iOS 27.0 b1 - b4。使用此方法时只有 MobileGestalt 可用，仅在 bad_query 无法正常工作时使用。",
        "**bad_query:** Supports iOS 27.0 b1 - b4. By [forcequit](https://github.com/forcequitOS).": "**bad_query：** 支持 iOS 27.0 b1 - b4。由 [forcequit](https://github.com/forcequitOS) 开发。",
        "Sandbox Extension Token.": "沙盒扩展 Token。",
        "Copy Token": "复制 Token",
        "Generate Token": "生成 Token",
        "Failed to get token.": "获取 Token 失败。",
        "Your sandbox token is valid.": "你的沙盒 Token 有效。",
        "Your sandbox token is invalid.": "你的沙盒 Token 无效。",
        "Disabled because the exploit failed. Is your iOS version supported?": "因 exploit 失败而禁用。你的 iOS 版本受支持吗？",
        "Keep Alive": "后台保活",
        "Keeps the app running in the background after you close it, allowing it to remain active.": "关闭应用后仍在后台保持运行，以便它能继续正常工作。",
        "Dismiss after importing": "导入后自动关闭",
        "When enabled, the Tendies explorer will close automatically after importing a .tendies file into PosterBoard.": "启用后，将 .tendies 文件导入 PosterBoard 时，Tendies 资源管理器会自动关闭。",
        "Persist after reboot": "重启后保留",
        "When enabled, MobileGestalt is written in-place on the same inode, which (hopefully) prevents iOS from regenerating the cache on reboot. Disable to use atomic file replacement instead.": "启用后，MobileGestalt 会在同一 inode 上原地写入，希望能防止 iOS 重启后重新生成缓存。关闭此选项则改用原子文件替换。",
        "Ignore exploit failure": "忽略 exploit 失败",
        "When enabled, All Tweaks will be accessible even if the exploit failed.": "启用后，即使 exploit 失败，所有插件仍可使用。",
        "Information": "说明",
        "Settings": "设置",
        "Tools": "工具",
        "Respring": "注销",
        "Respring method by [neon](https://github.com/neonmodder123), swift implementation by [skadz](https://github.com/skadz108).": "注销方法由 [neon](https://github.com/neonmodder123) 提供，Swift 实现由 [skadz](https://github.com/skadz108) 完成。",
        "Credits": "致谢",
        "Main developer": "主要开发者",
        "The bad_query exploit": "bad_query 漏洞利用",
        "His work on the MCM bug class": "MCM 漏洞类别的研究",
        "Tendies repository": "Tendies 资源库",
        "Done": "完成",
        "Are you sure?": "确定吗？",
        "Cancel": "取消",
        "Confirm": "确定",
        "Confirm that you want to respring.": "确认要注销吗？",

        // MARK: Logs (LogView)
        "Copy Output": "复制输出",

        // MARK: File browser (SantanderView)
        "Go to Root": "前往根目录",
        "Go to Home": "前往主目录",
        "Display hidden files": "显示隐藏文件",
        "Sort A-Z": "按 A-Z 排序",
        "Sort Z-A": "按 Z-A 排序",
        "No matching items.": "没有匹配的项目。",
        "No visible items. Enable \"Display hidden files\" to show dotfiles.": "没有可见项目。启用“显示隐藏文件”可查看点文件。",
        "Directory is empty.": "目录为空。",
        "No app containers found.": "未找到应用容器。",
        "Cannot list directory (missing permissions).": "无法列出目录（权限不足）。",
        "Not a directory.": "不是目录。",
        "Save": "保存",
        "Save Failed": "保存失败",
        "OK": "好",
        "Failed to render image": "无法渲染图像",
        "Error: %@": "错误：%@",
        "Missing write permission.": "缺少写入权限。",
        "Could not encode text.": "无法编码文本。",
        "Edited text is not a valid plist/JSON document.": "编辑后的内容不是有效的 plist/JSON 文档。",
        "(empty file)": "（空文件）",
        "Failed to read file:": "读取文件失败：",
        "Binary data (%d bytes). Showing first %d bytes:": "二进制数据（%d 字节）。正在显示前 %d 字节：",
        "Exists: %@": "存在：%@",
        "yes": "是",
        "no": "否",
        "Kind: %@": "类型：%@",
        "directory": "目录",
        "regular item": "常规项目",
        "UTType: %@": "UTType：%@",
        "Size: %d bytes": "大小：%d 字节",
        "Symlink: %@": "符号链接：%@",
        "Symlink target: %@": "符号链接目标：%@",
        "Alias file: %@": "别名文件：%@",
        "File attribute type: %@": "文件属性类型：%@",
        "Owner: %@ (%d)": "所有者：%@（%d）",
        "Owner: %@": "所有者：%@",
        "Owner ID: %d": "所有者 ID：%d",
        "Group: %@ (%d)": "组：%@（%d）",
        "Group: %@": "组：%@",
        "Group ID: %d": "组 ID：%d",
        "POSIX perms: %04o": "POSIX 权限：%04o",
        "Readable: %@": "可读：%@",
        "Writable: %@": "可写：%@",
        "Executable: %@": "可执行：%@",

        // MARK: MobileGestalt (GestaltView)
        "Do not reboot!": "不要重启！",
        "Your MobileGestalt.plist seems to be empty.": "你的 MobileGestalt.plist 似乎是空的。",
        "Your MobileGestalt.plist seems to be invalid.": "你的 MobileGestalt.plist 似乎无效。",
        "Warning": "警告",
        "Rebooting now might cause a bootloop. Try pressing 'Revert Tweaks'. If the warnings dont go away after that, you're fucked.": "此时重启可能会导致引导循环（bootloop）。请尝试点击“还原插件”。如果警告依然存在，那你就自求多福吧。",
        "Apply Tweaks": "应用插件",
        "Revert Tweaks": "还原插件",
        "**WARNING:** These tweaks have the capability to break features on your device or softbrick it if misused!": "**警告：** 使用不当，这些插件可能会导致设备功能异常甚至软变砖！",
        "Original (%@)": "原始（%@）",
        "Disable Dynamic Island": "关闭灵动岛",
        "iPhone X Gestures": "iPhone X 手势",
        "Subtype": "子类型",
        "Custom Device Name": "自定义设备名称",
        "Device Name": "设备名称",
        "Device Artwork": "设备机型",
        "Software-Oriented Features": "软件相关功能",
        "Hardware-Oriented Features": "硬件相关功能",
        "Spoofing": "伪装",
        "Default": "默认",
        "Eligibility": "资格",
        "Device Spoofing Info": "设备伪装说明",
        "Only spoof your device model if you want to download Apple Intelligence. This may break Face ID. If you decide to unspoof and want to keep Apple Intelligence, do NOT re-enter the Apple Intelligence & Siri menu in Settings.": "仅在你想下载 Apple Intelligence 时才伪装设备型号。这可能会导致 Face ID 失效。如果你决定取消伪装并想保留 Apple Intelligence，请勿再次进入“设置”中的“Apple Intelligence 与 Siri”菜单。",
        "iPadOS Features": "iPadOS 功能",
        "Internal": "内部功能",

        // MARK: MobileGestalt tweaks (mg.swift)
        "Warning!": "警告！",
        "Please do not use this feature to bypass region restrictions that would equate to breaking regional laws (e.g. disabling the camera shutter sound). We will NOT be held responsible for enabling any illegal activites!": "请不要使用此功能绕过等同于违反当地法律的地域限制（例如关闭相机快门声音）。对于由此产生的任何违法行为，我们概不负责！",
        "Failed to load current MobileGestalt!": "无法加载当前的 MobileGestalt！",
        "Restart the app and try again. Check logs for more detailed information.": "请重启应用后重试。查看日志可获取更详细的信息。",
        "Successfully applied Gestalt tweaks!": "已成功应用 Gestalt 插件！",
        "Respring your device for changes to take effect. Note that some tweaks may require a reboot for them to apply properly.": "注销设备后修改才会生效。注意：部分插件可能需要重启设备才能正确生效。",
        "Failed to apply MobileGestalt!": "无法应用 MobileGestalt！",
        "Successfully reverted Gestalt tweaks!": "已成功还原 Gestalt 插件！",
        "Reboot your device for changes to take effect.": "重启设备后修改才会生效。",
        "Failed to revert MobileGestalt!": "无法还原 MobileGestalt！",
        "Check logs for error information.": "请查看日志中的错误信息。",
        "Apple Intelligence Spoof": "Apple Intelligence 伪装",
        "Failed to get ArtworkDeviceSubType!": "无法获取 ArtworkDeviceSubType！",
        "Failed to get ArtworkDeviceProductDescription!": "无法获取 ArtworkDeviceProductDescription！",

        "Enable Dynamic Island Capability": "启用灵动岛功能",
        "An alternate way to enable the Dynamic Island, as used by Nugget.": "启用灵动岛的另一种方式，与 Nugget 相同。",
        "Always-On Display": "全天候显示",
        "Can increase screen burn-in risk on devices that don't officially support it.": "在不官方支持该功能的设备上，可能会增加烧屏风险。",
        "AOD Vibrancy": "AOD 鲜艳度",
        "Turn this on if your Always-On Display renders incorrectly.": "如果全天候显示渲染异常，请开启此项。",
        "Disable Wallpaper Parallax": "关闭壁纸视差效果",
        "Prevents the wallpaper from moving when you tilt or move the device.": "防止倾斜或移动设备时壁纸随之移动。",
        "Enable Liquid Glass Low-Performance Mode": "启用 Liquid Glass 低性能模式",
        "Intended for iOS 26 and newer.": "适用于 iOS 26 及更新版本。",
        "Disable Liquid Glass Low-Performance Mode": "关闭 Liquid Glass 低性能模式",
        "Don't use this at the same time as the option above.": "请勿与上面的选项同时开启。",
        "Boot & Shutdown Chime": "开机与关机提示音",
        "Adds the chime sound when the device powers on or shuts down.": "在设备开机或关机时播放提示音。",
        "Charge Limit Menu": "充电上限菜单",
        "Reveals the Settings menu; whether it actually limits charging depends on your hardware.": "显示“设置”中的对应菜单；是否真的能限制充电取决于你的硬件。",
        "Tap to Wake": "轻点唤醒",
        "Meant for devices like the iPhone SE where tapping to wake isn't otherwise available.": "适用于 iPhone SE 这类原本不支持轻点唤醒的设备。",
        "iPhone 16 Camera Control Settings": "iPhone 16 相机控制设置",
        "Exposes the Camera Control settings and its related capabilities.": "显示相机控制设置及其相关功能。",
        "Apple Pencil Settings": "Apple Pencil 设置",
        "Reveals the Apple Pencil settings page.": "显示 Apple Pencil 设置页面。",
        "Action Button Settings": "操作按钮设置",
        "Reveals the Action Button settings page.": "显示操作按钮设置页面。",
        "Collision SOS": "碰撞检测 SOS",
        "Reveals the collision detection options in the SOS settings.": "显示 SOS 设置中的碰撞检测选项。",
        "Pulse Width Modulation": "PWM 调光",
        "Security Research Device Mode": "安全研究设备模式",
        "Flags the device as an Apple Security Research Device.": "将设备标记为 Apple 安全研究设备。",
        "Allow iPad Apps": "允许 iPad 应用",
        "Allows iPad apps to be installed on iPhone.": "允许在 iPhone 上安装 iPad 应用。",
        "Stage Manager Support": "台前调度支持",
        "Flags the device as capable of Stage Manager.": "将设备标记为支持台前调度。",
        "Apple Internal Install": "Apple 内部安装",
        "Turns on internal features like the Metal HUD; some services may act up.": "开启 Metal HUD 等内部功能；部分服务可能会出现异常。",
        "Internal Storage View": "内部存储查看",
        "Displays internal files in the Storage settings; can be dangerous on some iPads.": "在“存储空间”设置中显示内部文件；在某些 iPad 上可能有风险。",
        "Disable Region Restrictions": "关闭地区限制",
        "This tweak may be broken or have no effect on some iOS versions or devices.": "此插件在某些 iOS 版本或设备上可能失效或无效。",
        "How to use this tweak:\n1. Spoof to the model next to the first one supported by Apple Intelligence.\n2. Spoof back to your model.\n3. Spoof to your final model and you should see the Apple Intelligence icon in Settings.\n4. Connect iPhone to power and leave the Settings > Storage tab open for ~1 hour.\n\nNOTE: Do not spoof back.": "使用方法：\n1. 先伪装到 Apple Intelligence 支持的首个机型的下一个机型。\n2. 再伪装回你自己的机型。\n3. 伪装到最终机型后，你应该能在“设置”中看到 Apple Intelligence 图标。\n4. 连接电源，并让“设置”>“存储空间”页面保持打开约 1 小时。\n\n注意：不要伪装回去。",
        "Enable iPadOS Mode": "启用 iPadOS 模式",
        "Experimental and high risk; This is a very dangerous tweak to use! If you use an alphanumeric passcode, DO NOT USE THIS TWEAK AT ALL! Please do not turn off \"Show Dock In Stage Manager\" or your device will BOOTLOOP when rotating to landscape! Some users have also reported that enabling the iPadOS UI and then tapping Stage Manager can cause the device to enter Recovery Mode, even when the UI itself appears unchanged. The Settings search bar may move to the top before this happens. With these three things in mind, you may experience general instability, or other major issues such as app data randomly disappearing. But I guess some funny multitasking features that still make the device relatively unusable are cool? Whatever dude, I'm not here to tell you how to use your own device.": "实验性功能，风险极高！此插件非常危险！如果你使用的是字母数字混合密码，请完全不要使用此插件！请勿关闭“台前调度中显示程序坞”，否则设备在旋转到横屏时会进入引导循环（BOOTLOOP）！部分用户反馈，启用 iPadOS 界面后点击“台前调度”，即使界面看起来没有变化，也可能导致设备进入恢复模式。发生这种情况前，“设置”的搜索栏可能会移动到顶部。考虑到以上三点，你可能会遇到系统不稳定等问题，例如应用数据无故消失。不过话说回来，那些花里胡哨但让设备几乎没法正常用的多任务功能确实挺酷？随你吧，我不是来教你怎么用你自己的设备的。",
        "Internal Features": "内部功能",

        // MARK: CacheExtra editor (CEView)
        "No CacheExtra fields": "没有 CacheExtra 字段",
        "No results": "没有结果",
        "Search for keys or values": "搜索键或值",
        "Saved": "已保存",
        "Field changes written to MobileGestalt. Respring for changes to take effect.": "字段修改已写入 MobileGestalt。注销后修改才会生效。",
        "Save failed": "保存失败",
        "Type": "类型",
        "Value": "值",
        "Key": "键",
        "Key name": "键名",
        "Add Field": "添加字段",
        "Add": "添加",
        "Key cannot be empty": "键不能为空",
        "Key already exists": "键已存在",
        "String": "字符串",
        "Integer": "整数",
        "Boolean": "布尔值",
        "Data (Base64)": "数据（Base64）",
        "Invalid Integer": "无效的整数",
        "Enter true/false": "请输入 true 或 false",
        "Invalid base64": "无效的 base64",
        "(empty str)": "（空字符串）",
        "Data (%d bytes)": "数据（%d 字节）",

        // MARK: PosterBoard (PosterView)
        "Apply": "应用",
        "Reset": "重置",
        "Import Tendies": "导入 Tendies",
        "Explore Tendies": "浏览 Tendies",
        "Import up to 5 wallpaper packs.\n**NOTE:** Importing more than 5 tendies at once is not a good idea and importing more than 15 is a TERRIBLE idea. Dont say I didnt warn you.": "最多导入 5 个壁纸包。\n**注意：** 一次导入超过 5 个 tendies 就不是什么好主意，超过 15 个更是糟糕透顶。别说我没提醒你。",
        "Imported": "已导入",
        "Successfully applied PosterBoard!": "已成功应用 PosterBoard！",
        "For changes to take effect:\n1. Click 'Open' to launch Posterboard\n2. Close it from the App Switcher": "为使修改生效：\n1. 点击“打开”启动 PosterBoard\n2. 从应用切换器中将其关闭",
        "Open": "打开",
        "Failed to apply PosterBoard!": "无法应用 PosterBoard！",
        "Successfully reverted PosterBoard!": "已成功还原 PosterBoard！",
        "Respring your device for changes to take effect.": "注销设备后修改才会生效。",
        "Failed to revert PosterBoard!": "无法还原 PosterBoard！",

        // MARK: Tendies (TendiesView)
        "Loading wallpapers…": "正在加载壁纸…",
        "Couldn't Load tendies": "无法加载 Tendies",
        "Try Again": "重试",
        "Search wallpapers": "搜索壁纸",
        "Import Failed": "导入失败",
        "Add to Imported": "加入已导入",
        "Downloading...": "正在下载…",
        "Preview Unavailable": "无法预览",
        "The wallpaper preview couldn't be loaded.": "壁纸预览加载失败。",
        "Download Failed": "下载失败",

        // MARK: App (mond.swift)
        "Not supported!": "不支持！",
        "Your iOS version may not be supported by mond.\nMond only supports iOS 27.0 developer beta 1 - 4.": "你的 iOS 版本可能不受 mond 支持。\nmond 仅支持 iOS 27.0 开发者测试版 1 - 4。",
    ]
}
