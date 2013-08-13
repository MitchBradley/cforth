#include "forth.h"
#include "dictfile.h"

import java.io.*;
import javax.microedition.midlet.*;
import javax.microedition.io.*;
import javax.microedition.lcdui.*;
import javax.microedition.pki.*;

public class forth extends MIDlet implements CommandListener {

//    SCOPE1 Command exitCmd = new Command("Exit", Command.EXIT, 2);

SCOPE1 TextBox cmdLine;

SCOPE1 Display display;

SCOPE1 int up;
SCOPE1 int[] word_dict;

SCOPE1 boolean firstTime;

SCOPE1 Command mExitCommand;
SCOPE1 Command mEnterCommand;

public forth() {
    up = prepare_dictionary();
    display = Display.getDisplay(this);
    cmdLine = new TextBox("This TB", "", 200, 0);
//    mExitCommand = new Command("Exit", Command.EXIT, 0);
    mEnterCommand = new Command("Enter", Command.ITEM, 0);
//    cmdLine.addCommand(mExitCommand);
    cmdLine.addCommand(mEnterCommand);
    cmdLine.setCommandListener(this);
    init_io();
    firstTime = true;
}

public void startApp()
    throws MIDletStateChangeException {
    if (firstTime) {
        firstTime = false;
        execute_word("quit");
    }
    display.setCurrent(cmdLine);
}

public void pauseApp() {
}

public void destroyApp(boolean unconditional) {
}

public void commandAction(Command c, Displayable s) {
//    if (c == mExitCommand) {
//        notifyDestroyed();
//        return;
//    }
    if (c == mEnterCommand) {
        finish_accept();
        return;
    }
}

SCOPE1 int
prepare_dictionary()
{
    int here;
    int xlimit;
    int[] variables;

    word_dict = new int[MAXDICT];
    variables = new int[MAXVARS];

    String dictionary_file = "";

    xlimit = MAXDICT;

    dictionary_file = DEFAULT_EXE;

    here = read_dictionary(dictionary_file, variables);

    if (here == 0)
        return 0;

    return init_compiler(here, xlimit, variables);
}

SCOPE1 int
read_dictionary(String fname, IntArray variables)
{
    DataInputStream fd;
    int here;
    int usize;

//    try {
        fd = new DataInputStream(getClass().getResourceAsStream(fname));
//    }
//    catch (Exception e) {
//        System.err.println("Can't open dictionary file " + fname);
//        return 0;
//    }

    try {
        if (fd.readInt() != MAGIC) {
            System.err.println("Bad magic number in dictionary file " + fname);
            return 0;
        }

        fd.readInt();  // Unused field
        fd.readInt();  // Unused field
         
        here  = fd.readInt();
        up    = fd.readInt();
        usize = fd.readInt();

        fd.readInt();  // Unused field
        fd.readInt();  // Unused field

        for (int i = 0; i < here; i++)
            DATA(i) = fd.readInt();

        for (int i = 0; i < usize; i++)
            variables[i] = fd.readInt();

        fd.close();
    }
    catch (IOException e) {
        return 0;
    }

    return here;
}
