# FlutterFlow Gemma 3n On-Device AI Chat

This repository contains the source code for a multi-modal AI chat application built using FlutterFlow and powered by Google's Gemma 3n on-device models. The application serves as a demonstration of how to leverage FlutterFlow's custom code capabilities to integrate and interact with advanced, on-device AI models.

## Features

*   **On-Device AI Chat:** All AI processing is handled directly on the device, ensuring privacy and offline functionality.
*   **Multi-Modal Input:** The application accepts both text and image-based inputs.
*   **FlutterFlow Integration:** Built entirely within the FlutterFlow platform, showcasing the power of low-code development combined with custom code extensions.

## Technical Overview

This project highlights the synergy between the rapid development environment of FlutterFlow and the power of on-device AI with Gemma 3n.

### FlutterFlow

The application leverages several of FlutterFlow's advanced features to achieve its functionality:

*   **Custom Widgets:** The user interface for the chat and model selection is built using custom widgets. This allows for a tailored user experience that goes beyond the standard widgets available in FlutterFlow. Custom widgets are essential for creating unique UI elements and integrating third-party packages.
*   **Custom Actions:** Custom actions are used to handle the logic of the application, such as processing user input, interacting with the Gemma 3n model, and managing the chat history. These actions are written in Dart and can be triggered by user interactions within the app.
*   **Custom Classes:** Custom classes are utilized to manage the data structures and state of the application in a more organized and efficient manner.

### Gemma 3n

The core of this application's intelligence lies in the Gemma 3n series of models from Google. These models are specifically designed for efficient execution on low-resource devices like smartphones and tablets.

*   **Multi-Modality:** Gemma 3n models are inherently multi-modal, capable of processing text, images, audio, and video. This application demonstrates the text and image input capabilities.
*   **On-Device Performance:** Engineered for efficiency, Gemma 3n models are available in different sizes (e.g., E2B and E4B) that are optimized for on-device use with a small memory footprint. This is achieved through innovations like Per-Layer Embeddings (PLE) which reduce RAM usage.
*   **Advanced Architecture:** The models are built on a shared architecture that also powers the next generation of Gemini Nano, showcasing the cutting-edge technology being used. They also feature a Matryoshka Transformer (MatFormer) architecture that allows for selective parameter activation to reduce compute cost.

## How to Use

To run this application, you will need to have a FlutterFlow account.

1.  **Clone the Repository:**
2.  **Import into FlutterFlow:** Import the cloned repository into your FlutterFlow account.
3.  **Configure HuggingFace Token:** In the application's settings, you will need to enter your HuggingFace token to download and use the Gemma models.
4.  **Run the Application:** Once configured, you can run the application in the FlutterFlow environment or deploy it to a device.
