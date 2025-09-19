# 🐛 shai-hulud-scanner

Bash script to scan npm packages and subpackages for the infected **Shai Hulud** worm and reports them directly to the console. ⚠️

## 🚀 Usage

To run the scanner, you need to provide:

1. A text file containing the list of npm packages to check (`packages.txt`). 📄  
2. The path to the project directory you want to scan. 📂

Run the script using:

```bash
sh shai-hulud-scan.sh packages.txt /path/to/project
```

The script will process each package listed in `packages.txt`, scan the specified project for infections, and display the results in your console. 🖥️

### 📝 Example `packages.txt`

```
express
react
lodash
```

Each line should contain the name of a package you want to check. (Format: package@version)

## 🤝 Contributing

Found a bug 🐞 or want to improve the scanner? We welcome contributions!  

1. Fork the repository 🍴  
2. Create your feature branch (`git checkout -b feature-name`) 🌱  
3. Commit your changes (`git commit -m 'Add some feature'`) ✍️  
4. Push to the branch (`git push origin feature-name`) 🚀  
5. Open a Pull Request 📨  

Let's keep our projects safe from the Shai Hulud worm together! 💪

## 📌 Notes

- Make sure you have **bash** installed and available in your PATH.  
- Run the script from a terminal with sufficient permissions to access the project directory.  
