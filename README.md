# Proto-Balatro (LÖVE 2D Prototype)

A very simple prototype inspired by Balatro, built with LÖVE 2D.

## Requirements

- [LÖVE 2D](https://love2d.org/) (tested with version 11.x, but should work with recent versions)

## How to Run

1.  **Ensure LÖVE 2D is installed** and accessible from your command line or that you know where the executable is.

2.  **Navigate** to the directory containing this README file (`Prototipas` folder).

3.  **Run using one of the following methods:**
    *   **Command Line:** Open your terminal or command prompt in the `Prototipas` directory and run:
        ```bash
        love .
        ```
    *   **Drag and Drop:** Drag the `Prototipas` folder directly onto the `love.exe` (Windows), `love.app` (macOS), or `love` (Linux) executable.
    *   **(Alternative) Create a `.love` file:**
        *   Zip the *contents* of the `Prototipas` folder (i.e., `main.lua` and `card.lua` should be at the root of the zip archive).
        *   Rename the resulting `.zip` file to `Proto-Balatro.love`.
        *   Run the `.love` file using the command line (`love Proto-Balatro.love`) or by dragging it onto the LÖVE executable.

## Controls

-   **Mouse Click:** Click on cards to select/deselect them.
-   **Escape Key:** Quit the game. 