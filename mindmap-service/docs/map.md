flowchart TD

%% =========================
%% Nodes
%% =========================
N1["Object-Oriented Programming<br/><sub>OOP is a programming paradigm based on the concept of objects</sub>"]

N2["Encapsulation<br/><sub>Bundling data and methods that operate on that data within a single unit (class), restricting direct access to some components</sub>"]
N3["Inheritance<br/><sub>A mechanism where a new class inherits properties and behaviors from an existing class</sub>"]
N4["Polymorphism<br/><sub>The ability of objects to take on many forms - same interface, different implementations</sub>"]
N5["Abstraction<br/><sub>Hiding complex implementation details and showing only essential features</sub>"]

N6["Private Fields<br/><sub>Use private access modifier to hide internal state</sub>"]
N7["Getters/Setters<br/><sub>Public methods to access and modify private fields</sub>"]

N8["extends keyword<br/><sub>Used to inherit from a parent class</sub>"]
N9["super keyword<br/><sub>Reference to parent class constructor/methods</sub>"]

%% =========================
%% PART_OF edges (topics under OOP)
%% =========================
N2 -->|PART_OF| N1
N3 -->|PART_OF| N1
N4 -->|PART_OF| N1
N5 -->|PART_OF| N1

%% =========================
%% EXPLAINS edges (subtopics explain topic)
%% =========================
N6 -->|EXPLAINS| N2
N7 -->|EXPLAINS| N2

N8 -->|EXPLAINS| N3
N9 -->|EXPLAINS| N3

%% =========================
%% PREREQ edges (learning order / dependency)
%% =========================
N2 -->|PREREQ| N3
N3 -->|PREREQ| N4
