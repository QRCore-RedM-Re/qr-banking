# qr-banking
- Banking System for QR-Core

## Features
- Withdraw / Deposit
- Transfer Funds
- Savings Account

## Dependencies
- [qr-core](https://github.com/QRCore-framework/qb-core)
- [qr-smallresources](https://github.com/QRCore-RedM-Re/qr-smallresources) - Log bank activity

## Screenshots
![image](https://user-images.githubusercontent.com/101474430/232979374-0b8dca96-3991-47d5-8002-e4e68d4a5a75.png)
![image](https://user-images.githubusercontent.com/101474430/232979409-1dd9def9-3d09-4149-9748-ef2c0ace766e.png)
![image](https://user-images.githubusercontent.com/101474430/232979443-d1ba5ee2-8441-4da9-b0d0-71e04e03656e.png)

## Installation
- Download the script and put it in the `[qr]` directory.
- Import `qr-banking.sql` in your database
- Add the following code to your server.cfg
```
ensure qr-core
ensure qr-smallresources
ensure qr-banking
```
- (Optional) Enable target functionality from server.cfg
```
setr UseTarget true
```

# Issues, Suggestions & Support
* This resource is still in development. All help with improving the resource is encouraged and appreciated
* Please use the [GitHub](https://github.com/QRCore-RedM-Re) issues system to report issues or make suggestions
* When making suggestions, please keep `[Suggestion]` in the title to make it clear that it is a suggestion, or join the Discord
* Discord: https://discord.gg/bEs6cn3225