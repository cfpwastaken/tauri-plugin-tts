use tauri::{command, AppHandle, Runtime};

use crate::models::*;
use crate::Result;
use crate::TtsExt;

// #[command]
// pub(crate) async fn ping<R: Runtime>(
//     app: AppHandle<R>,
//     payload: PingRequest,
// ) -> Result<PingResponse> {
//     app.tts().ping(payload)
// }

#[command]
pub(crate) async fn speak<R: Runtime>(app: AppHandle<R>, text: String) -> Result<()> {
    app.tts().speak(text)
}
