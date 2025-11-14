// onboarding_page_data.dart


class OnboardingContent {
  final String imagePath;
  final String title;
  final String description;

  OnboardingContent({
    required this.imagePath,
    required this.title,
    required this.description,
  });
}

// 🚨 ACTION REQUIRED: Verify the image paths below.
final List<OnboardingContent> contents = [
  OnboardingContent(
    imagePath: "assets/images/screen1.jpg",
    title: "Welcome to EventFlow",
    description: "Experience moments of culture and celebration, effortlessly.",
  ),
  OnboardingContent(
    imagePath: "assets/images/screen2.jpg",
    title: "Discover & Connect",
    description: "Easily find and explore festivals based on your location and interests.",
  ),
  OnboardingContent(
    imagePath: "assets/images/screen3.jpg",
    title: "Book & Go!",
    description: "Simple checkout and digital tickets. Ready to light up your next moment.",
  ),
];