# Gemma On-Device AI FlutterFlow Project

This project is a complete FlutterFlow integration of Google's powerful Gemma family of AI models, designed to provide offline, on-device AI capabilities. It features authenticated model downloads from HuggingFace, a streamlined setup process, and a real-time, multimodal chat interface that supports both text and image inputs.

This repository serves as a robust template and a practical example for developers looking to integrate local, server-independent AI into their FlutterFlow applications.

## 🚀 Features

* **On-Device Inference**: All AI processing happens directly on the user's device, ensuring data privacy and offline functionality.
* **Multimodal Capabilities**: Interact with the AI using both text and images, powered by models like PaliGemma and SmolVLM.
* **Authenticated Model Downloads**: Securely download a wide range of AI models directly from HuggingFace using a personal access token.
* **Dynamic Model Selection**: A user-friendly dropdown allows users to select, download, and set up their preferred AI model from a curated list.
* **Complete Chat UI**: A ready-to-use chat widget (`GemmaChatWidget`) provides a familiar interface for interacting with the AI.
* **Streamlined Setup**: The `GemmaSimpleSetupWidget` handles the entire download, installation, and initialization process with clear progress indicators.
* **Built with FlutterFlow**: Easily customize and extend the application using FlutterFlow's low-code interface, while leveraging powerful custom code for core AI functionality.

## 🛠️ Getting Started

Follow these steps to get the application running on your local machine.

### Prerequisites

* Flutter SDK installed on your machine.
* A code editor like VS Code.

### 1. Clone the Repository

First, clone this repository to your local machine:

```bash
git clone <your-repository-url>
cd <repository-directory>
````

### 2\. Get a HuggingFace User Access Token

To download the Gemma and other gated models, you need a HuggingFace User Access Token.

1.  Go to your HuggingFace account settings: [**huggingface.co/settings/tokens**](https://huggingface.co/settings/tokens).
2.  Create a new token with at least `read` permissions.
3.  Copy the token. You will need it to run the app.

### 3\. Run the Application

When you first run the application, it will start on the **Setup Page**. The application is designed to use this token to authenticate with HuggingFace.

1.  Install dependencies:
    ```bash
    flutter pub get
    ```
2.  Run the app:
    ```bash
    flutter run
    ```

The app state is managed by `FFAppState`, which securely stores your HuggingFace token on the device using `flutter_secure_storage`. The setup widgets use this token to perform the download.

### 4\. Select and Download a Model

On the setup screen, you will see a dropdown menu.

1.  **Select a model** from the list.
2.  The **Gemma Model Setup** widget will appear.
3.  Click the **"Setup Gemma Model"** button to begin the download and installation process.
4.  Once complete, you will be automatically navigated to the chat page, ready to interact with your on-device AI.

## 🤖 Available Models

You can choose from a variety of text-only and multimodal models. The application is pre-configured with the following options:

| **Model ID** | **Name / Description** | **Type** | **Recommended Use Case** |
| ------------------ | ---------------------------------------------------- | ----------------- | ----------------------------- |
| `smolvlm-500m`     | SmolVLM 500M - Smallest multimodal model             | Multimodal        | Web & Mobile (Low Memory)     |
| `gemma3-1b-web`    | Gemma3 1B - Web-optimized text model                 | Text-Only         | Web & Mobile (Low Memory)     |
| `nanollava`        | nanoLLaVA - Compact and efficient multimodal model   | Multimodal        | Mobile Apps                   |
| `smolvlm-2b`       | SmolVLM 2.2B - Higher quality multimodal model       | Multimodal        | Multimodal Tasks              |
| `paligemma-3b-448` | PaliGemma 3B - High-resolution vision model          | Multimodal        | Multimodal Tasks              |
| `idefics2-8b-ocr`  | Idefics2 8B - Specialized for OCR & documents        | Multimodal        | OCR & Documents               |
| `paligemma-3b-896` | PaliGemma 3B - Ultra high-res for document analysis  | Multimodal        | High Quality / OCR            |
| `rmbg-1.4-onnx`    | RMBG 1.4 - Background removal utility                | Computer Vision   | Image Processing              |

*This list is generated from the metadata within `lib/custom_code/actions/download_authenticated_model.dart`.*

## 🏗️ Project Architecture

The project's core logic is encapsulated in custom code, making it easy to manage and extend.

  * **`lib/custom_code/GemmaManager.dart`**: This is the heart of the application. It's a singleton class that manages the entire lifecycle of the AI model:
      * Initializing the model with a specific backend (GPU or CPU).
      * Creating and managing inference sessions.
      * Handling the sending of messages (text and images) to the model.
  * **`lib/custom_code/actions/`**: These files contain custom actions that bridge the gap between FlutterFlow's UI and the `GemmaManager`.
      * `download_authenticated_model.dart`: Fetches models from HuggingFace.
      * `install_local_model_file.dart`: Installs a downloaded model file.
      * `initialize_gemma_model.dart`: Initializes the model for inference.
      * `create_gemma_session.dart`: Creates a chat session.
      * `get_downloaded_models.dart`: Lists models already saved on the device.
  * **`lib/custom_code/widgets/`**: These are custom widgets that provide the main user interfaces.
      * `gemma_simple_setup_widget.dart`: A self-contained widget that guides the user through the entire model setup process.
      * `gemma_chat_widget.dart`: A complete chat interface for sending and receiving messages and images.
  * **`lib/pages/`**: These are the main pages of the application.
      * `setup_widget.dart`: The initial screen that hosts the model selection dropdown and the setup widget.
      * `home_page_widget.dart`: The screen that will host the main chat interface once setup is complete.

## 🎨 Customization

This project is designed to be a starting point. Here are a few ways you can customize it:

  * **Add New Models**: To add support for a new model, you can update the maps inside `lib/custom_code/actions/download_authenticated_model.dart`. Add the new model's ID, download URL, and metadata.
  * **Modify the UI**: Use the FlutterFlow editor to change the appearance of the `Setup` and `HomePage` pages. You can integrate the `GemmaChatWidget` into any part of your application.
  * **Extend Functionality**: Create new custom actions to perform different tasks with the model's output, such as text summarization, data extraction, or function calling.

