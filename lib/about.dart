import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/custom_background.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: CustomBackground(
        child: Stack(
          children: [
            // Fixed content
            SafeArea(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start, // Align content to the left
                children: [
                  Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: size.width * 0.04),
                    child: Text(
                      "About Us.",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 255, 255, 255),
                      ),
                    ),
                  ),
                  SizedBox(height: size.height * 0.02),
                  Hero(
                    tag: 'about-image',
                    child: Container(
                      margin:
                          EdgeInsets.symmetric(horizontal: size.width * 0.04),
                      constraints: BoxConstraints(
                        maxWidth: size.width * 0.9,
                        maxHeight: size.height * 0.3,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.asset(
                          'assets/about1.png',
                          fit: BoxFit.cover,
                          width: size.width * 0.9,
                          height: size.height * 0.3,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: size.height * 0.03),
                  Expanded(
                    child: Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: size.width * 0.04),
                      child: Text.rich(
                        TextSpan(
                          children: [
                            const TextSpan(text: "Welcome to "),
                            TextSpan(
                              text: "HMS EGG DISTRIBUTORS",
                              style: TextStyle(
                                color: const Color.fromARGB(255, 255, 14, 14),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextSpan(
                              text:
                                  ", your trusted source for premium-quality eggs. ",
                            ),
                            TextSpan(
                              text:
                                  "Founded with a passion for delivering freshness and consistency, we are committed to supplying businesses and retailers with the finest eggs available — ensuring quality in every tray. ",
                            ),
                            TextSpan(
                              text: "Visit us at hmsegg.com",
                              style: TextStyle(
                                color: Colors.blue,
                                decoration: TextDecoration.underline,
                                fontWeight: FontWeight.bold,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  launchUrl(Uri.parse("https://hmsegg.com"));
                                },
                            ),
                          ],
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  // Extra space to prevent content from being obscured by fixed complaint box
                  SizedBox(height: size.height * 0.25),
                ],
              ),
            ),
            // Fixed Complaint Box
            Positioned(
              bottom: size.height * 0.02,
              left: size.width * 0.04,
              right: size.width * 0.04,
              child: Container(
                padding: EdgeInsets.all(size.width * 0.05),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFFB71C1C).withOpacity(0.85), // Deep red
                      Color(0xFF8B0000).withOpacity(0.85), // Darker red
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: Color(0xFFB71C1C).withOpacity(0.5),
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      "Complaint Box",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: size.height * 0.015),
                    Text(
                      "If you experience any issues or dissatisfaction with our driver or helper, please contact us at:",
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: size.height * 0.015),
                    GestureDetector(
                      onTap: () async {
                        final Uri phoneUri = Uri(
                          scheme: 'tel',
                          path:
                              '+919900956387', // Replace with Noor Ahmed's number
                        );
                        if (await canLaunchUrl(phoneUri)) {
                          await launchUrl(phoneUri);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Unable to open dialer')),
                          );
                        }
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: size.width * 0.03,
                          vertical: size.height * 0.000001,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.phone,
                              color: Color.fromARGB(255, 255, 255, 255),
                              size: 22,
                            ),
                            SizedBox(width: size.width * 0.02),
                            Text(
                              "+91 9900956387", // Replace with Noor Ahmed's number
                              style: TextStyle(
                                color: Color.fromARGB(255, 255, 255, 255),
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
