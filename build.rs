const COMMANDS: &[&str] = &["speak", "stop", "configure", "is_available", "get_voices"];

fn main() {
    tauri_plugin::Builder::new(COMMANDS)
        .android_path("android")
        .ios_path("ios")
        .build();
}
