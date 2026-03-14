const COMMANDS: &[&str] = &["speak", "stop", "configure"];

fn main() {
    tauri_plugin::Builder::new(COMMANDS)
        .android_path("android")
        .ios_path("ios")
        .build();
}
