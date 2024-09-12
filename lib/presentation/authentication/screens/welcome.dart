import 'package:bookings/presentation/authentication/screens/login.dart';
import 'package:bookings/presentation/authentication/screens/signup.dart';
import 'package:bookings/presentation/authentication/widgets/button.dart';
import 'package:flutter/material.dart';
import 'package:bookings/presentation/authentication/widgets/bg.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BackgroundScaffold(      
      children: [
        Positioned.fill(
          child: Image.asset(
            'assets/images/bg.png',
            fit: BoxFit.cover,
          ),
        ),
      ],
      child: Column(
        children: [
          Flexible(
            flex: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(
                vertical: 0,
                horizontal: 40.0,
              ),
              child: Center(
                child: RichText(
                  textAlign: TextAlign.center,
                text: const TextSpan(
                  children: [
                    TextSpan(
                      text: 'Welcome to Muniafu Hotel!\n',
                      style: TextStyle(
                        fontSize: 45.0,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFAC1919),
                      )
                    ),
                    TextSpan(
                      text: 
                      '\nWe are delighted to have you with us. Your comfort is our top priority. Thank you for choosing us!',
                      style: TextStyle(
                        fontSize: 20,
                        color: Color(0xFFAC1919),
                      )
                    )
                  ]
                )
              ),
            ),
          )
        ),
        const Flexible(
          flex: 1,
          child: Align(
            alignment: Alignment.bottomCenter,
          child: Row(
            children: [
              Expanded(child: WelcomeButton(
                buttonText: 'Sign Up',
                onTap: SignUpScreen(),
                color: Color(0xFF000000),
                textColor: Color(0xFFF44336),
              ),),
              Expanded(child: WelcomeButton(
                buttonText: 'Log In',
                onTap: LoginScreen(),
                color: Color(0xFFF44336),
                textColor: Color(0xFF000000),
              ),),
            ],
          ),
          ),
        ),
        ],
      )
    );
  }
}