import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:crypto/crypto.dart';
import 'package:file_saver/file_saver.dart';

encrypt.Key deriveKey(String password, {int keyLength = 32, int iterations = 1000, String salt = 'salt'}) {
  final keyBytes = utf8.encode(password).sublist(0, keyLength);
  return encrypt.Key(Uint8List.fromList(keyBytes));
}

encrypt.IV deriveIV(String password, {int ivLength = 16}) {
  final hash = sha256.convert(utf8.encode(password));
  return encrypt.IV(Uint8List.fromList(hash.bytes.sublist(0, ivLength)));
}

Future<void> encryptAndSaveFile(Uint8List fileBytes, String fileName, String password) async {
  final key = deriveKey(password);
  final iv = deriveIV(password);

  final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));
  final encryptedBytes = encrypter.encryptBytes(fileBytes, iv: iv).bytes;

  await FileSaver.instance.saveFile(
    name: fileName,
    bytes: Uint8List.fromList(encryptedBytes),
    ext: 'enc',
    mimeType: MimeType.other,
  );
}

Future<Uint8List?> decryptFile(Uint8List encryptedBytes, String password) async {
  final key = deriveKey(password);
  final iv = deriveIV(password);

  final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));
  try {
    final decryptedBytes = encrypter.decryptBytes(encrypt.Encrypted(encryptedBytes), iv: iv);
    return Uint8List.fromList(decryptedBytes);
  } catch (e) {
    print("Decryption error: $e");
    return null;
  }
}


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Uint8List? _fileBytes;
  String? _fileName;
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("EnCipher"),
      ),
      body: Container(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            const Text(
              "File Encrypter/Decrypter",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold
              ),
            ),
            const SizedBox(height: 10),
            const Text("Secure your files with a password."),
            const SizedBox(height: 40),
            InkWell(
              onTap: () async {
                FilePickerResult? result = await FilePicker.platform.pickFiles(
                  allowMultiple: false,
                );
                if (result != null) {
                  setState(() {
                    _fileBytes = result.files.first.bytes;
                    _fileName = result.files.first.name;
                  });
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.black12,
                  ),
                  borderRadius: BorderRadius.circular(5),
                  boxShadow: const [
                    BoxShadow(
                      color: Color.fromRGBO(17, 12, 46, 0.15),
                      blurRadius: 100,
                      spreadRadius: 0,
                      offset: Offset(0, 48),
                    ),
                  ]                
                ),
                padding: const EdgeInsets.all(10.0),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(Icons.file_upload),
                    Text("Upload/Pick File")
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text("Password"),
            const SizedBox(height: 5),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.symmetric(
                  vertical: 4,
                  horizontal: 10
                ),
                hintText: "Enter Password",
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 45,
                    child: ElevatedButton(
                      onPressed: _fileBytes != null ? () async {
                        final password = _passwordController.text;
                        if (password.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Password cannot be empty'))
                          );
                          return;
                        }

                        await encryptAndSaveFile(_fileBytes!, _fileName!, password);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('File encrypted and saved successfully'))
                        );
                      } : null,
                      child: const Text("Encrypt")
                    ),
                  )
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: SizedBox(
                    height: 45,
                    child: TextButton(
                      onPressed: _fileBytes != null ? () async {
                        final password = _passwordController.text;
                        if (password.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Password cannot be empty'))
                          );
                          return;
                        }

                        final decryptedBytes = await decryptFile(_fileBytes!, password);
                        if (decryptedBytes != null) {
                          await FileSaver.instance.saveFile(
                            name: _fileName!.replaceAll('.enc', ''),
                            bytes: decryptedBytes,
                            ext: '',
                            mimeType: MimeType.other,
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('File decrypted and saved successfully'))
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Decryption failed. Check your password.'))
                          );
                        }
                      } : null,
                      child: const Text("Decrypt")
                    ),
                  )
                ),
              ],
            ),
            const SizedBox(height: 5),
            const Spacer(),
            const Center(
              child: Text(
                "BUILD BY HAPPER WITH ❤️",
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 12,
                  fontWeight: FontWeight.bold
                ),
              )
            )
          ],
        ),
      )
    );
  }
}
