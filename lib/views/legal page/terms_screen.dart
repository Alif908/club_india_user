import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

// ─────────────────────────────────────────────────────────────
// Shared Legal Page Scaffold
// ─────────────────────────────────────────────────────────────

class LegalPage extends StatelessWidget {
  final String title;
  final List<LegalSection> sections;

  const LegalPage({required this.title, required this.sections});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1C1C2E)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Color(0xFF1C1C2E),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
        children: [
          // Header card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF0F5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFFE0EC)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.update_rounded,
                  size: 16,
                  color: Color(0xFFFF2D78),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Last Updated: 15 June 2026',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFFFF2D78),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ...sections.map((s) => _SectionCard(section: s)),
          const SizedBox(height: 16),
          // Contact footer
          _ContactFooter(),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Section Card
// ─────────────────────────────────────────────────────────────

class LegalSection {
  final String number;
  final String title;
  final String body;
  final List<String>? bullets;

  const LegalSection({
    required this.number,
    required this.title,
    required this.body,
    this.bullets,
  });
}

class _SectionCard extends StatelessWidget {
  final LegalSection section;

  const _SectionCard({required this.section});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFF0F0F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF2D78),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    section.number,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    section.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              section.body,
              style: const TextStyle(
                fontSize: 13.5,
                color: Color(0xFF555555),
                height: 1.55,
              ),
            ),
            if (section.bullets != null && section.bullets!.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...section.bullets!.map(
                (b) => Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 6),
                        child: CircleAvatar(
                          radius: 3,
                          backgroundColor: Color(0xFFFF2D78),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          b,
                          style: const TextStyle(
                            fontSize: 13.5,
                            color: Color(0xFF555555),
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Contact Footer
// ─────────────────────────────────────────────────────────────

class _ContactFooter extends StatelessWidget {
  Future<void> _launchEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'Bestagencyindia2026@gmail.com',
    );
    await launchUrl(emailUri, mode: LaunchMode.externalApplication);
  }

  Future<void> _launchDeleteUrl() async {
    final Uri url = Uri.parse(
      'https://coinapi.bestagencyindia.com/delete-user.html',
    );
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0F5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFE0EC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.business, size: 18, color: Color(0xFFFF2D78)),
              SizedBox(width: 8),
              Text(
                'Contact Us',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Best Agency India\nCapitanse Technology Private Limited\nThrissur, Kerala, India',
            style: TextStyle(
              fontSize: 13.5,
              color: Color(0xFF555555),
              height: 1.6,
            ),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: _launchEmail,
            child: const Row(
              children: [
                Icon(Icons.mail_outline, size: 16, color: Color(0xFFFF2D78)),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Bestagencyindia2026@gmail.com',
                    style: TextStyle(
                      fontSize: 13.5,
                      color: Color(0xFFFF2D78),
                      fontWeight: FontWeight.w500,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: _launchDeleteUrl,
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.delete_outline, size: 16, color: Color(0xFFFF2D78)),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Delete Account:\ncoinapi.bestagencyindia.com/delete-user.html',
                    style: TextStyle(
                      fontSize: 13.5,
                      color: Color(0xFFFF2D78),
                      fontWeight: FontWeight.w500,
                      decoration: TextDecoration.underline,
                    ),
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

// ═════════════════════════════════════════════════════════════
// 1. TERMS AND CONDITIONS PAGE
// ═════════════════════════════════════════════════════════════

class TermsAndConditionsPage extends StatelessWidget {
  const TermsAndConditionsPage({super.key});

  static const _sections = <LegalSection>[
    LegalSection(
      number: '1',
      title: 'Eligibility',
      body:
          'You must be at least 18 years old and legally capable of entering into binding agreements.',
    ),
    LegalSection(
      number: '2',
      title: 'User Registration',
      body:
          'The App requires mobile number verification through OTP authentication. Users agree to provide accurate and complete information during registration and profile creation.',
    ),
    LegalSection(
      number: '3',
      title: 'User Information',
      body: 'Users may provide the following information:',
      bullets: [
        'Name',
        'Mobile number',
        'Email address',
        'State, district, and city',
        'GPS location',
        'Bank account details',
        'UPI information',
      ],
    ),
    LegalSection(
      number: '4',
      title: 'OTP Authentication',
      body:
          'Users must register a valid mobile number and complete OTP verification. Users must not share OTPs, use another person\'s mobile number, or attempt unauthorized access.',
    ),
    LegalSection(
      number: '5',
      title: 'Rewards Program',
      body:
          'Badacoin may offer reward points, cashback, promotional benefits, and loyalty rewards. The Company may modify reward rules, change reward values, suspend reward programs, or cancel rewards obtained through fraud. Reward points are promotional loyalty rewards only and are not cryptocurrency, digital assets, securities, investment products, or legal tender. Reward points have no guaranteed cash value and may be modified or discontinued at any time.',
    ),
    LegalSection(
      number: '6',
      title: 'Wallet Services',
      body:
          'The App may display reward balances, earnings history, redemption history, and withdrawal requests. Displayed balances are subject to verification by the Company.',
    ),
    LegalSection(
      number: '7',
      title: 'Withdrawals',
      body:
          'Users may request withdrawals subject to minimum withdrawal limits, verification requirements, fraud checks, and operational review. Withdrawal requests may take up to 7 business days to process. The Company reserves the right to reject, delay, reverse, or cancel withdrawal requests where necessary.',
    ),
    LegalSection(
      number: '8',
      title: 'Location Services',
      body:
          'The App may collect location information to show nearby stores, verify user location, improve services, and prevent fraud. Location access may be disabled through device settings, but certain features may not function correctly. By enabling location services, users consent to collection and processing of location information for operational purposes.',
    ),
    LegalSection(
      number: '9',
      title: 'Notifications',
      body:
          'The App may send notifications regarding offers, rewards, promotions, wallet activity, security alerts, and system updates. Users may disable notifications through device settings.',
    ),
    LegalSection(
      number: '10',
      title: 'User Responsibilities',
      body: 'Users agree not to:',
      bullets: [
        'Create fake accounts',
        'Submit false information',
        'Abuse reward systems',
        'Manipulate location information',
        'Attempt unauthorized access',
        'Use the App unlawfully',
      ],
    ),
    LegalSection(
      number: '11',
      title: 'Fraud Prevention',
      body:
          'The Company may investigate suspicious activities including fake registrations, multiple accounts, reward abuse, and unauthorized transactions. Accounts may be suspended or terminated during investigations.',
    ),
    LegalSection(
      number: '12',
      title: 'Rewards Abuse Policy',
      body:
          'The Company may suspend, restrict, or terminate accounts involved in fake referrals, multiple account creation, reward manipulation, or fraudulent transactions.',
    ),
    LegalSection(
      number: '13',
      title: 'Account Deletion',
      body:
          'Users may request account deletion at any time through https://coinapi.bestagencyindia.com/delete-user.html or by contacting support. Upon deletion, access to the App will be terminated and reward balances may be forfeited. The Company may retain certain information where required for legal obligations, fraud prevention, financial record retention, security investigations, and dispute resolution.',
    ),
    LegalSection(
      number: '14',
      title: 'Intellectual Property',
      body:
          'All App content, trademarks, logos, graphics, databases, software, and related materials remain the property of the Company.',
    ),
    LegalSection(
      number: '15',
      title: 'Account Suspension',
      body:
          'The Company may suspend or terminate accounts for violation of these Terms, fraudulent activity, security concerns, or legal compliance requirements.',
    ),
    LegalSection(
      number: '16',
      title: 'Disclaimer',
      body:
          'The App is provided on an "AS IS" and "AS AVAILABLE" basis. The Company makes no guarantees regarding continuous availability, error-free operation, accuracy of content, or compatibility with all devices.',
    ),
    LegalSection(
      number: '17',
      title: 'Limitation of Liability',
      body:
          'To the fullest extent permitted by law, the Company shall not be liable for indirect, incidental, special, or consequential damages arising from use of the App.',
    ),
    LegalSection(
      number: '18',
      title: 'Changes to Terms',
      body:
          'The Company may update these Terms at any time. Continued use of the App constitutes acceptance of updated Terms.',
    ),
    LegalSection(
      number: '19',
      title: 'Governing Law',
      body:
          'These Terms shall be governed by the laws of India. Any disputes shall be subject to the exclusive jurisdiction of the courts located in Thrissur, Kerala, India.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return LegalPage(title: 'Terms & Conditions', sections: _sections);
  }
}
