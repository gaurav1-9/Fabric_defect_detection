import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:async';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Fabric Defect Detection',
      theme: ThemeData(
        primarySwatch: Colors.lime,
      ),
      home: const MyHomePage(
        title: 'Fabric Defect Detection',
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  File? _image;
  var jsonResponse = null;

  Future getImage(ImageSource source) async {
    try {
      final image = await ImagePicker().pickImage(source: source);
      if (image == null) return;

      final imagePermanaent = await saveFilePermanently(image.path);
      setState(() {
        this._image = imagePermanaent;
      });
      print("Image: ${basename(_image!.path)}");
    } on PlatformException catch (e) {
      print("Failed to pick image: $e");
    }
  }

  Future<File> saveFilePermanently(String imagePath) async {
    final diectory = await getApplicationDocumentsDirectory();
    final name = basename(imagePath);
    final image = File('${diectory.path}/$name');

    return File(imagePath).copy(image.path);
  }

  void uploadImage(File imageFile) async {
    var stream = http.ByteStream(imageFile.openRead());
    var length = await imageFile.length();

    var uri = Uri.parse(
        'http://192.168.43.246:65432/img_flask/${basename(imageFile.path)}');
    var request = http.MultipartRequest('POST', uri);

    var multipartFile = http.MultipartFile('image', stream, length,
        filename: imageFile.path.split('/').last);
    request.files.add(multipartFile);

    var response = await request.send();

    if (response.statusCode == 200) {
      var responseBody = await response.stream.bytesToString();
      print('Response body: $responseBody');

      try {
        jsonResponse = json.decode(responseBody);
        setState(() {
          this.jsonResponse = jsonResponse['Defective'];
        });
      } catch (e) {
        print('Error parsing JSON: $e');
      }
    } else {
      print('Image upload failed with status ${response.statusCode}');
      print(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(children: [
          const SizedBox(
            height: 40,
          ),
          _image != null
              ? Column(
                  children: [
                    Image.file(
                      _image!,
                      width: 250,
                      height: 250,
                      fit: BoxFit.cover,
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    customButton(
                      title: "Analyze Image...",
                      icon: Icons.settings_outlined,
                      onClick: () => uploadImage(_image!),
                      w: 183,
                      h: 40,
                    ),
                  ],
                )
              : Center(
                  child: Column(
                    children: const [
                      Icon(Icons.broken_image_rounded),
                      Text("No image selected"),
                    ],
                  ),
                ),
          const SizedBox(
            height: 40,
          ),
          customButton(
            title: "Choose an image from gallery",
            icon: Icons.image,
            onClick: () => getImage(ImageSource.gallery),
            w: 265,
            h: 60,
          ),
          const SizedBox(
            height: 40,
          ),
          jsonResponse != null
              ? jsonResponse == true
                  ? const Text(
                      "DEFECTIVE FABRIC ❌",
                      style: TextStyle(
                          fontSize: 25,
                          color: Colors.red,
                          fontWeight: FontWeight.bold),
                    )
                  : const Text(
                      "GOOD FABRIC ✔️",
                      style: TextStyle(
                          fontSize: 25,
                          color: Colors.green,
                          fontWeight: FontWeight.bold),
                    )
              : const SizedBox(
                  height: 40,
                ),
        ]),
      ),
    );
  }
}

Widget customButton({
  required String title,
  required IconData icon,
  required VoidCallback onClick,
  required double w,
  required double h,
}) {
  return SizedBox(
    width: w,
    height: h,
    child: ElevatedButton(
      onPressed: onClick,
      child: Center(
        child: Row(
          children: [
            Icon(icon),
            const SizedBox(
              width: 20,
            ),
            Text(title),
          ],
        ),
      ),
    ),
  );
}
