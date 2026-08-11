import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_colors.dart';


void showDeleteConfirmationDialog({
  required BuildContext context,
  required VoidCallback onDeleteConfirm,
}) {
  bool isDeleted = false;

  showDialog(
    context: context,
    builder: (BuildContext dialogContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            insetPadding: const EdgeInsets.symmetric(horizontal: 28),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // --- TOP CLOSE BUTTON ---
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: () => Navigator.of(dialogContext).pop(),
                      child: const Icon(
                        Icons.close,
                        size: 20,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // --- ICON AREA ---
                  if (!isDeleted)
                  // Initial Trash Icon
                    const Icon(
                      Icons.delete_outline_rounded,
                      size: 54,
                      color: Color(0xFF333333),
                    )
                  else
                  // Success Trash Icon with Green Check Badge
                    SizedBox(
                      width: 58,
                      height: 58,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          const Icon(
                            Icons.delete_outline_rounded,
                            size: 50,
                            color: Color(0xFF333333),
                          ),
                          Positioned(
                            top: 2,
                            right: 4,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: Color(0xFF37C871),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check,
                                size: 12,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 20),

                  // --- TITLE TEXT ---
                  Text(
                    isDeleted
                        ? "List has been deleted"
                        : "Are you sure want to delete?",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.nunito(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF2B2B2B),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // --- GRADIENT ACTION BUTTON ---
                  Container(
                    width: double.infinity,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: AppColors.orangeGradient,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        if (!isDeleted) {
                          onDeleteConfirm();
                          setState(() {
                            isDeleted = true;
                          });
                        } else {
                          Navigator.of(dialogContext).pop();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        isDeleted ? "Ok" : "Delete",
                        style: GoogleFonts.nunito(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  // --- CANCEL BUTTON ---
                  if (!isDeleted) ...[
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () => Navigator.of(dialogContext).pop(),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Text(
                          "Cancel",
                          style: GoogleFonts.nunito(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF2B2B2B),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      );
    },
  );
}