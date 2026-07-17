\ makeapp.fth - Generate app.dic from t*.o files for ESP32

\ Load cross-compiled objects
s" tmain.o" $add-obj
s" tforth.o" $add-obj
s" tcompiler.o" $add-obj
s" tio.o" $add-obj
s" tdictfile.o" $add-obj
s" textend.o" $add-obj
s" tsyscall.o" $add-obj
s" tfloatops.o" $add-obj
s" tlineedit.o" $add-obj
s" tmallocl.o" $add-obj
s" tsyswrap.o" $add-obj

\ Generate app.dic
s" app.dic" $save-dict
