import 'package:flutter/material.dart';
import 'package:libbit_chat_app/features/authentication/controllers/auth_controller.dart';
import 'package:libbit_chat_app/features/authentication/ui/widgets/authentication_form_widget.dart';
import 'package:libbit_chat_app/utils/constants/color_constants.dart';
import 'package:provider/provider.dart';

class AuthenticationScreen extends StatelessWidget {
  const AuthenticationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthController(),
      child: Scaffold(
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.only(
              left: 24,
              top: kToolbarHeight + 48,
              right: 24,
              bottom: 48,
            ),
            child: SizedBox(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/logos/libbit_logo_light_transparent.png',
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Welcome',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: ColorConstants.highlightPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Link up and start chatting anytime, anywhere!',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: ColorConstants.neutralMedium,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const AuthenticationFormWidget(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
