import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/custom_background.dart'; // Adjust if needed

class ContactUsScreen extends StatelessWidget {
  const ContactUsScreen({super.key});

  void _launchPhone(String phoneNumber) async {
    final Uri url = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  void _launchEmailViaWeb() async {
    final Uri gmailWeb = Uri.parse(
      'https://mail.google.com/mail/?view=cm&fs=1&to=hmseggdistrubutors87@gmail.com&su=Hello&body=I%20would%20like%20to%20get%20in%20touch%20with%20you',
    );

    if (await canLaunchUrl(gmailWeb)) {
      await launchUrl(gmailWeb, mode: LaunchMode.externalApplication);
    } else {
      debugPrint('❌ Could not launch Gmail web compose');
    }
  }

  Widget buildCard(String title, Map<String, String> contacts) {
    return Expanded(
      child: Card(
        color: const Color.fromARGB(255, 255, 255, 255),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 6,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.location_on),
                    onPressed: () {
                      launch(
                          'https://www.google.com/maps/place/H.M.S+EGG+DISTRIBUTOR/@12.9481843,77.5260843,17z');
                    },
                  )
                ],
              ),
              const Text("Contact Numbers",
                  style: TextStyle(fontWeight: FontWeight.w500)),
              ...contacts.entries.map(
                (entry) => Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(entry.key,
                        style: const TextStyle(
                            color: Color.fromARGB(255, 0, 0, 0))),
                    IconButton(
                      icon: const Icon(Icons.phone),
                      onPressed: () => _launchPhone(entry.value),
                    )
                  ],
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _launchEmailViaWeb,
                icon: const Icon(Icons.email),
                label: const Text("Email Us"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(40),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Contact Us.",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 255, 255, 255),
                  ),
                ),
                const Text(
                  "Branch 1",
                  style: TextStyle(fontSize: 16, color: Colors.black),
                ),
                const SizedBox(height: 8),
                buildCard("Bengaluru", {
                  "Noor Ahmed": "9900956387",
                  "Tanveer Pasha": "8892650006",
                  "Sagheer Ahmed": "8867786887",
                }),
                const Text(
                  "Branch 2",
                  style: TextStyle(fontSize: 16, color: Colors.black),
                ),
                buildCard("Kolar", {
                  "Noor Ahmed": "9900956387",
                  "Tanveer Pasha": "8892650006",
                  "Sagheer Ahmed": "8867786887",
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
