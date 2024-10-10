import 'package:flutter/material.dart';

InputDecoration getAuthenticationInputDecoration(String label) {
  return InputDecoration( 
    labelText: label,  
    labelStyle: const TextStyle(
      color: Color.fromARGB(255, 142, 142, 142), 
      fontSize: 16, 
      fontFamily: 'Poppins',
    ),
    fillColor: const Color.fromARGB(255, 235, 255, 254),
    filled: true,
    contentPadding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
    ),
    enabledBorder: const OutlineInputBorder(
      borderSide: BorderSide(color: Color.fromARGB(255, 142, 142, 142), width: 0.5), 
    ),
    focusedBorder: const OutlineInputBorder(
      borderSide: BorderSide(color: Color.fromARGB(255, 119, 199, 156), width: 2),
    ),
  );
}

