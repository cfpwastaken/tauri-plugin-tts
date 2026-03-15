use tauri::{command, AppHandle, Runtime};

use crate::Result;
use crate::TtsExt;
use crate::models::AvailableResult;
use crate::models::VoicesResult;

#[command]
pub(crate) async fn speak<R: Runtime>(app: AppHandle<R>, text: String, language: Option<String>) -> Result<()> {
    app.tts().speak(text, language)
}

#[command]
pub(crate) async fn stop<R: Runtime>(app: AppHandle<R>) -> Result<()> {
    app.tts().stop()
}

#[command]
pub(crate) async fn configure<R: Runtime>(app: AppHandle<R>) -> Result<()> {
    app.tts().configure()
}

#[command]
pub(crate) async fn is_available<R: Runtime>(app: AppHandle<R>, language: String) -> Result<AvailableResult> {
    app.tts().is_available(language)
}

#[command]
pub(crate) async fn get_voices<R: Runtime>(app: AppHandle<R>) -> Result<VoicesResult> {
    app.tts().get_voices()
}
