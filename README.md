# Marky - Watermark Generator

Marky - Watermark Generator is a Flutter-based web application designed for easily applying watermarks to images. With options for customization and multiple image uploads, it's an all-in-one solution for branding and copyrighting your photos.

## Features

- **Multiple Image Uploads**: Upload several images at once and apply watermarks to them in a batch.
- **Diagonal Watermark Orientation**: Watermarks are strategically placed in a diagonal orientation from bottom-left to top-right for a stylish look.
- **Customizable Watermark Density**: Use the slider to adjust the frequency/density of the watermark across the image.
- **Customizable Watermark Opacity**: Determine the transparency of your watermark for optimal visibility.
- **Dynamic Initial Watermark Text**: The watermark text field is pre-filled with a dynamic message based on the current date, but you're free to customize it to your needs.
- **Download Options**: Download watermarked images individually or in bulk, offering flexibility for various use cases.
- **Simple UI**: An intuitive user interface ensures that users, even without technical expertise, can easily watermark their images.

## Requirements

- Flutter SDK version 3.13.1

## Setup

1. **Install Flutter**: Follow the [official guide](https://flutter.dev/docs/get-started/install) to set up Flutter on your machine.
2. **Clone the Repository**:
   ```bash
   git clone [repository_url]
   cd [repository_directory]
   ```
3. **Run the Application**:
   ```bash
   flutter run -d web
   ```

## Usage

1. **Upload Images**: Click on the "Upload Image" button and select one or multiple images.
2. **Set Watermark Text**: A default text, based on the current date and a preset message, will be provided. However, you can customize this text as per your requirements.
3. **Adjust Watermark Density**: Use the density slider to change the frequency of the watermark across your image.
4. **Adjust Watermark Opacity**: Use the opacity slider to modify the transparency of the watermark.
5. **Apply Watermark**: After setting your preferences, click on the "Apply Watermark" button. The watermark will be applied to all the uploaded images.
6. **Download the Images**: Post watermarking, you have the option to download images individually or all at once using the respective buttons.

## Contributing

Contributions, issues, and feature requests are welcome. For major changes, please open an issue first to discuss your proposed change.

## License

This project is open-source and available under the [MIT License](https://choosealicense.com/licenses/mit/).
