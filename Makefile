TARGET=Atauto.sh
SUBCMD=get_testcase
SUBC=$(SUBCMD).c
INSDIR=$(HOME)/.local/bin


install:
	mkdir -p ../AtCoder ../AtCoder/input ../AtCoder/output $(HOME)/.config/Atauto
	cp src/$(TARGET) $(INSDIR)/$(TARGET)
	cp confs/* $(HOME)/.config/Atauto
	gcc -Wall -o $(SUBCMD) src/$(SUBC)
	mv $(SUBCMD) $(INSDIR)
	echo "...installed"

uninstall:
	rm $(INSDIR)/$(SUBCMD) $(INSDIR)/$(TARGET)
	rm -rf $(HOME)/.config/Atauto
	echo "...uninstalled"
