use tauri::{command, AppHandle, Runtime};

use crate::Result;
use crate::TtsExt;

#[command]
pub(crate) async fn speak<R: Runtime>(app: AppHandle<R>, text: String) -> Result<()> {
    app.tts().speak(text)
}

#[command]
pub(crate) async fn stop<R: Runtime>(app: AppHandle<R>) -> Result<()> {
    app.tts().stop()
}
