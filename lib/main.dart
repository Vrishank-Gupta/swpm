import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/widgets.dart' as pw;
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'constants.dart' as Constants;
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:flutter_rating_bar/flutter_rating_bar.dart';


void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Story Generator',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  TextEditingController promptController = TextEditingController();
  String generatedStory = '';
  bool isLoading = false;

  Future<void> fetchData(String prompt) async {
    setState(() {
      isLoading = true;
    });

    final url = Uri.parse('https://jsonplaceholder.typicode.com/posts'); // Replace with your API endpoint
    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        // Assuming the response is in JSON format
        final responseData = jsonDecode(response.body);

        // Extract necessary information from responseData
        String sceneSetting = responseData[0]['body'];
        String theme = responseData[0]['title'];

        // Send data to another API for story generation (Replace 'genAIEndpoint' with the actual endpoint)
        final genAIEndpoint = Uri.parse('https://jsonplaceholder.typicode.com/posts');
        final genAIResponse = await http.post(genAIEndpoint, body: {
          'prompt': prompt,
          'sceneSetting': sceneSetting,
          'theme': theme,
        });

        if (genAIResponse.statusCode == 201) {
          // Assuming the response is in JSON format
          final genAIResult = jsonDecode(genAIResponse.body);

          // Extract and set the generated story
          setState(() {
            generatedStory = genAIResult['sceneSetting'];
            generatedStory = Constants.generatedStory;
            String sceneSettingStream = genAIResult['prompt'];
            isLoading = false;
          });
        } else {
          // Handle error from genAI API
          print('Error from genAI API: ${genAIResponse.statusCode}');
          setState(() {
            isLoading = false;
          });
        }
      } else {
        // Handle error from xyz.com API
        print('Error from xyz.com API: ${response.statusCode}');
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error: $e');
      setState(() {
        isLoading = false;
      });
    }
  }


  Future<void> generateAndDownloadPDF() async {
    Directory output = await path_provider.getTemporaryDirectory();

    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (context) => pw.Center(
          child: pw.Text(generatedStory),
        ),
      ),
    );

    final pdfFile = File("D:/swpm/generated_story.pdf");
    await pdfFile.writeAsBytes(await pdf.save());

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('PDF Generated and Downloaded'),
        action: SnackBarAction(
          label: 'Open',
          onPressed: () {
            // Use Platform.isIOS or Platform.isAndroid to check the platform
            if (Platform.isIOS || Platform.isAndroid) {
              OpenFile.open(pdfFile.path);
            } else {
              print('Download feature is not supported on this platform.');
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Story Generator'),
      ),
      body: Stack(
        children: [
          // Background Image
          Image.asset(
            'assets/background_image.jpg',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextField(
                  controller: promptController,
                  decoration: InputDecoration(labelText: 'Enter your prompt',
                    filled: true, //<-- SEE HERE
                    fillColor: Colors.white,
                  ),
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    String userPrompt = promptController.text;
                    fetchData(userPrompt);
                  },
                  child: Text('Generate Story'),
                ),
                SizedBox(height: 16),

                // Loading Indicator
                if (isLoading)
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  )
                else
                // Generated Story
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text(
                          'Generated Story:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8),
                        Text(generatedStory),
                        SizedBox(height: 16),

                        // Button to Generate PDF
                        ElevatedButton(
                          onPressed: generateAndDownloadPDF,
                          child: Text('Download PDF'),
                        ),
                        // Star Rating System
                        SizedBox(height: 16),
                        Text('Rate the story:'),
                        RatingBar.builder(
                          initialRating: 4,
                          minRating: 1,
                          direction: Axis.horizontal,
                          allowHalfRating: true,
                          itemCount: 5,
                          itemPadding: EdgeInsets.symmetric(horizontal: 4.0),
                          itemBuilder: (context, _) => Icon(
                            Icons.star,
                            color: Colors.amber,
                          ),
                          onRatingUpdate: (rating) {
                            print(rating);
                          },),
                        TextField(
                          decoration: InputDecoration(labelText: 'Enter your feedback',
                            filled: false, //<-- SEE HERE
                            fillColor: Colors.white,
                          ),
                        ),
                        SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            String userPrompt = promptController.text;
                            fetchData(userPrompt);
                          },
                          child: Text('Submit Feedback'),
                        ),

                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
