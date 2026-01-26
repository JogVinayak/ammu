package com.learning.notes_service.model.enums;

public enum NoteStatus {
    DRAFT,       // Being prepared/edited
    IN_REVIEW,   // Submitted for review, awaiting approval
    READY,       // Approved and ready (in teacher's library)
    RELEASED,    // Released to students
    ARCHIVED     // Soft deleted
}
