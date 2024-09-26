// ignore_for_file: prefer_const_constructors, use_super_parameters, prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';
import "package:dev_icons/dev_icons.dart";

class AboutPage extends StatefulWidget {
  const AboutPage({Key? key}) : super(key: key);

  @override
  _AboutPageState createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("About CITE Spotlight",
            style: TextStyle(color: Colors.white)),
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
        backgroundColor: Colors.green.shade800,
        elevation: 0,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Check screen width for responsiveness
          bool isDesktop = constraints.maxWidth > 800;
          double padding = isDesktop ? 32.0 : 16.0;
          double titleFontSize = isDesktop ? 28 : 24;
          double sectionTitleFontSize = isDesktop ? 24 : 20;
          double bodyFontSize = isDesktop ? 18 : 16;

          return SingleChildScrollView(
            padding: EdgeInsets.all(padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Application summary section
                Text(
                  "CITE Spotlight",
                  style: TextStyle(
                      fontSize: titleFontSize, fontWeight: FontWeight.bold),
                ),
                Divider(),
                SizedBox(height: 8),
                Text(
                  "CITE Spotlight is inspired by the popular HOTorNOT website. However, "
                  "instead of simply rating, users participate in a nomination and voting "
                  "system to determine the hottest individuals. Users can nominate someone they "
                  "find attractive, after which a voting phase occurs where participants vote for the "
                  "hottest male and female nominees. The winners are automatically determined once the "
                  "voting session ends, making the competition fair and engaging!",
                  style: TextStyle(
                    fontSize: bodyFontSize,
                    color: Colors.grey,
                  ),
                ),
                SizedBox(height: 16),

                // How to use section
                Text(
                  "How to Use CITE Spotlight",
                  style: TextStyle(
                      fontSize: sectionTitleFontSize,
                      fontWeight: FontWeight.bold),
                ),
                Divider(),
                SizedBox(height: 8),
                Text(
                  "1. Nominate: Users can nominate someone they think is the hottest person.\n"
                  "2. Voting: After nominations are submitted, users can vote for the hottest "
                  "nominee in each gender category (male and female).\n"
                  "3. Results: Once the voting period ends, the winners for each gender are automatically "
                  "determined and announced.",
                  style: TextStyle(
                    fontSize: bodyFontSize,
                    color: Colors.grey,
                  ),
                ),
                SizedBox(height: 16),

                // Developers section
                Center(
                  child: Text(
                    "Developers",
                    style: TextStyle(
                        fontSize: sectionTitleFontSize,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                Divider(),
                SizedBox(height: 8),

                // Developer Cards Section
                isDesktop
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: DeveloperCard(
                              name: "Angelo C. Serafino",
                              role: "Full Stack Developer",
                              gitIcon: DevIcons.githubOriginal,
                              github: "DnqxteAngelo",
                              avatarUrl:
                                  "https://atsgdlgyikeqipysmvzf.supabase.co/storage/v1/object/public/nominee-images/developer.png",
                              tools: [
                                {
                                  "icon": DevIcons.flutterPlain,
                                  "label": "Flutter"
                                },
                                {"icon": DevIcons.dartPlain, "label": "Dart"},
                                {
                                  "icon": DevIcons.javascriptPlain,
                                  "label": "JavaScript"
                                },
                                {
                                  "icon": DevIcons.reactOriginal,
                                  "label": "React"
                                },
                                {
                                  "icon": DevIcons.nextjsOriginal,
                                  "label": "NextJS"
                                },
                                {
                                  "icon": DevIcons.tailwindcssPlain,
                                  "label": "TailwindCSS"
                                },
                                {
                                  "icon": DevIcons.postgresqlPlain,
                                  "label": "PostgreSQL"
                                },
                                {"icon": DevIcons.mysqlPlain, "label": "MySQL"},
                              ],
                              isDesktop: isDesktop,
                            ),
                          ),
                          const SizedBox(width: 16), // Spacing between cards
                          Expanded(
                            child: DeveloperCard(
                              name: "Andrew Albert G. Talaboc",
                              role: "Full Stack Developer",
                              gitIcon: DevIcons.githubOriginal,
                              github: "officiallerio",
                              avatarUrl:
                                  "https://atsgdlgyikeqipysmvzf.supabase.co/storage/v1/object/public/nominee-images/113695382.jpeg",
                              tools: [
                                {
                                  "icon": DevIcons.javascriptPlain,
                                  "label": "JavaScript"
                                },
                                {
                                  "icon": DevIcons.typescriptPlain,
                                  "label": "TypeScript"
                                },
                                {
                                  "icon": DevIcons.reactOriginal,
                                  "label": "React"
                                },
                                {
                                  "icon": DevIcons.nextjsOriginal,
                                  "label": "NextJS"
                                },
                                {
                                  "icon": DevIcons.tailwindcssPlain,
                                  "label": "TailwindCSS"
                                },
                                {"icon": DevIcons.phpPlain, "label": "PHP"},
                                {
                                  "icon": DevIcons.postgresqlPlain,
                                  "label": "PostgreSQL"
                                },
                                {"icon": DevIcons.mysqlPlain, "label": "MySQL"},
                              ],
                              isDesktop: isDesktop,
                            ),
                          ),
                        ],
                      )
                    : Column(
                        children: [
                          DeveloperCard(
                            name: "Angelo C. Serafino",
                            role: "Full Stack Developer",
                            gitIcon: DevIcons.githubOriginal,
                            github: "DnqxteAngelo",
                            avatarUrl:
                                "https://atsgdlgyikeqipysmvzf.supabase.co/storage/v1/object/public/nominee-images/developer.png",
                            tools: [
                              {
                                "icon": DevIcons.flutterPlain,
                                "label": "Flutter"
                              },
                              {"icon": DevIcons.dartPlain, "label": "Dart"},
                              {
                                "icon": DevIcons.javascriptPlain,
                                "label": "JavaScript"
                              },
                              {
                                "icon": DevIcons.reactOriginal,
                                "label": "React"
                              },
                              {
                                "icon": DevIcons.nextjsOriginal,
                                "label": "NextJS"
                              },
                              {
                                "icon": DevIcons.tailwindcssPlain,
                                "label": "TailwindCSS"
                              },
                              {
                                "icon": DevIcons.postgresqlPlain,
                                "label": "PostgreSQL"
                              },
                              {"icon": DevIcons.mysqlPlain, "label": "MySQL"},
                            ],
                            isDesktop: isDesktop,
                          ),
                          const SizedBox(height: 8),
                          DeveloperCard(
                            name: "Andrew Albert G. Talaboc",
                            role: "Full Stack Developer",
                            gitIcon: DevIcons.githubOriginal,
                            github: "officiallerio",
                            avatarUrl:
                                "https://atsgdlgyikeqipysmvzf.supabase.co/storage/v1/object/public/nominee-images/113695382.jpeg",
                            tools: [
                              {
                                "icon": DevIcons.javascriptPlain,
                                "label": "JavaScript"
                              },
                              {
                                "icon": DevIcons.typescriptPlain,
                                "label": "TypeScript"
                              },
                              {
                                "icon": DevIcons.reactOriginal,
                                "label": "React"
                              },
                              {
                                "icon": DevIcons.nextjsOriginal,
                                "label": "NextJS"
                              },
                              {
                                "icon": DevIcons.tailwindcssPlain,
                                "label": "TailwindCSS"
                              },
                              {"icon": DevIcons.phpPlain, "label": "PHP"},
                              {
                                "icon": DevIcons.postgresqlPlain,
                                "label": "PostgreSQL"
                              },
                              {"icon": DevIcons.mysqlPlain, "label": "MySQL"},
                            ],
                            isDesktop: isDesktop,
                          ),
                        ],
                      ),

                // Footer with All Rights Reserved
                SizedBox(height: 32),
                Center(
                  child: Column(
                    children: [
                      Divider(),
                      SizedBox(height: 8),
                      Text(
                        "© ${DateTime.now().year} CITE Spotlight. All Rights Reserved.",
                        style: TextStyle(
                          fontSize: bodyFontSize - 2,
                          color: Colors.grey.shade600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// Developer Card Widget
class DeveloperCard extends StatelessWidget {
  final String name;
  final String role;
  final String github;
  final IconData gitIcon;
  final String avatarUrl;
  final List<Map<String, dynamic>> tools;
  final bool isDesktop;

  const DeveloperCard({
    Key? key,
    required this.name,
    required this.role,
    required this.github,
    required this.gitIcon,
    required this.avatarUrl,
    required this.tools,
    required this.isDesktop,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: isDesktop ? 40 : 30,
                  backgroundImage: NetworkImage(avatarUrl),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                            fontSize: isDesktop ? 20 : 18,
                            fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            gitIcon,
                            color: Colors.grey,
                            size: 18,
                          ),
                          SizedBox(width: 4),
                          Text(
                            github,
                            style: const TextStyle(
                                fontSize: 16, color: Colors.grey),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Text(
                        role,
                        style:
                            const TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              ],
            ),
            Divider(),
            SizedBox(height: 16),
            Text(
              "Tools & Programming Languages:",
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black),
            ),
            SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isDesktop
                    ? 3
                    : 2, // Adjust column count based on screen size
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 3 / 1,
              ),
              itemCount: tools.length,
              itemBuilder: (context, index) {
                return Row(
                  children: [
                    Icon(
                      tools[index]['icon'],
                      color: Colors.green.shade800,
                    ),
                    SizedBox(width: 8),
                    Text(
                      tools[index]['label'],
                      style: const TextStyle(
                        fontSize: 14,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
