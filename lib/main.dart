import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:path/path.dart' show join;
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as Img;

Future<void> main() async {
  // Ensure that plugin services are initialized so that `availableCameras()`
  // can be called before `runApp()`
  WidgetsFlutterBinding.ensureInitialized();

  // Obtain a list of the available cameras on the device.
  final cameras = await availableCameras();

  // Get a specific camera from the list of available cameras.
  final firstCamera = cameras.first;

  runApp(
    MaterialApp(
      theme: ThemeData.dark(),
      home: TakePictureScreen(
        // Pass the appropriate camera to the TakePictureScreen widget.
        camera: firstCamera,
      ),
    ),
  );
}

// A screen that allows users to take a picture using a given camera.
class TakePictureScreen extends StatefulWidget {
  final CameraDescription camera;

  const TakePictureScreen({
    Key key,
    @required this.camera,
  }) : super(key: key);

  @override
  TakePictureScreenState createState() => TakePictureScreenState();
}

class TakePictureScreenState extends State<TakePictureScreen> {
  CameraController _controller;
  Future<void> _initializeControllerFuture;

  @override
  void initState() {
    super.initState();
    // To display the current output from the Camera,
    // create a CameraController.
    _controller = CameraController(
      // Get a specific camera from the list of available cameras.
      widget.camera,
      // Define the resolution to use.
      ResolutionPreset.medium,
    );

    // Next, initialize the controller. This returns a Future.
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    // Dispose of the controller when the widget is disposed.
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Take a picture')),
      // Wait until the controller is initialized before displaying the
      // camera preview. Use a FutureBuilder to display a loading spinner
      // until the controller has finished initializing.
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            // If the Future is complete, display the preview.
            return CameraPreview(_controller);
          } else {
            // Otherwise, display a loading indicator.
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.camera_alt),
        // Provide an onPressed callback.
        onPressed: () async {
          // Take the Picture in a try / catch block. If anything goes wrong,
          // catch the error.
          try {
            // Ensure that the camera is initialized.
            await _initializeControllerFuture;

            // Construct the path where the image should be saved using the
            // pattern package.
            final path = join(
              // Store the picture in the temp directory.
              // Find the temp directory using the `path_provider` plugin.
              (await getExternalStorageDirectory()).path,
              '${DateTime.now()}.png',
            );
            print(path);

            // Attempt to take a picture and log where it's been saved.
            await _controller.takePicture(path);

            // If the picture was taken, display it on a new screen.
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DisplayPictureScreen(imagePath: path),
              ),
            );
          } catch (e) {
            // If an error occurs, log the error to the console.
            print(e);
          }
        },
      ),
    );
  }
}

class DisplayPictureScreen extends StatefulWidget {
  final String imagePath;
  const DisplayPictureScreen({Key key, this.imagePath}) : super(key: key);
  @override
  _DisplayPictureScreenState createState() => _DisplayPictureScreenState();
}

class _DisplayPictureScreenState extends State<DisplayPictureScreen> {
  bool authorized = false;
  @override
  void initState() {
    // checkPer();
    super.initState();
  }

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    var knockDir =
        await new Directory('${directory.path}/cam').create(recursive: true);
    print(directory.path);
    print(knockDir.path);
    return knockDir.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/counter.jpg');
  }

  Future<File> writeCounter() async {
    Directory directory = await getApplicationDocumentsDirectory();
    File temp = File(widget.imagePath);
    Img.Image image = Img.decodeImage(temp.readAsBytesSync());
    String pathName =
        '${directory.path.toString()}/image_${DateTime.now()}.png';
    print(pathName);
    File dFile = File(pathName);
    dFile.writeAsBytesSync(Img.encodePng(image));

//     final directory = await getExternalStorageDirectory();
// final myImagePath = '${directory.path}/MyImages' ;
// final myImgDir = await new Directory(myImagePath).create();
// var kompresimg = new File("$myImagePath/image_$baru$rand.jpg")
//   ..writeAsBytesSync(img.encodeJpg( File(widget.imagePath).readAsBytes(), quality: 95));
    // final file = await _localFile;
    // List<int> imageBytes = await File(widget.imagePath).readAsBytes();
    // // Write the file
    // return file.writeAsBytes(imageBytes);
  }

  // void checkPer() async {
  //   await new Future.delayed(new Duration(seconds: 1));
  //   bool checkResult = await SimplePermissions.checkPermission(
  //       Permission.WriteExternalStorage);
  //   if (!checkResult) {
  //     var status = await SimplePermissions.requestPermission(
  //         Permission.WriteExternalStorage);
  //     //print("permission request result is " + resReq.toString());
  //     if (status == PermissionStatus.authorized) {
  //       authorized = true;
  //     }
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Display the Picture')),
      // The image is stored as a file on the device. Use the `Image.file`
      // constructor with the given path to display the image.
      body: Image.file(
        File(widget.imagePath),
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.save),
        onPressed: () {
          writeCounter();
        },
      ),
    );
  }
}

// A widget that displays the picture taken by the user.
