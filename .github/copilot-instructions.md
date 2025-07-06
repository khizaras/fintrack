# Copilot Instructions for FinTrack Flutter App

<!-- Use this file to provide workspace-specific custom instructions to Copilot. For more details, visit https://code.visualstudio.com/docs/copilot/copilot-customization#_use-a-githubcopilotinstructionsmd-file -->

## Project Overview

This is a Flutter mobile application called "FinTrack" that automatically reads SMS messages from banks and financial institutions to track expenses and income. The app categorizes transactions, provides spending insights, and allows users to set budgets.

## Architecture Guidelines

- Follow Clean Architecture principles with clear separation of concerns
- Use BLoC (Business Logic Component) pattern for state management
- Implement Repository pattern for data access
- Use dependency injection with get_it package
- Follow Material Design 3 guidelines for UI/UX

## Code Style Guidelines

- Use dart format for code formatting
- Follow effective Dart naming conventions
- Use meaningful variable and function names
- Add comprehensive documentation for public APIs
- Implement proper error handling and logging

## Key Features to Implement

1. SMS reading and transaction extraction
2. Automatic transaction categorization
3. Local SQLite database storage with encryption
4. User authentication and profile management
5. Budget management with notifications
6. Spending insights and visualizations
7. Data export functionality
8. Privacy and security compliance

## Security Considerations

- Implement proper permission handling for SMS access
- Use encrypted local storage for sensitive data
- Follow GDPR compliance for data handling
- Implement secure authentication mechanisms
- Regular security audits for SMS parsing logic

## Testing Strategy

- Write unit tests for business logic
- Integration tests for database operations
- Widget tests for UI components
- End-to-end tests for critical user flows

## Dependencies to Consider

- sqflite: Local database storage
- permission_handler: Managing SMS permissions
- crypto: Data encryption
- telephony: SMS reading functionality
- fl_chart: Data visualizations
- bloc: State management
- get_it: Dependency injection
- shared_preferences: Simple data storage
