const COMMANDS: &[&str] = &["speak", "stop", "configure", "is_available"];

fn main() {
    tauri_plugin::Builder::new(COMMANDS)
        .android_path("android")
        .ios_path("ios")
        .build();
}
