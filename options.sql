 # sql options population script
 # used for "nethack.options" table
 # this is for nethack, not slashem
 # pooya woodcock

 delete from options;

 INSERT INTO options VALUES (null,'autopickup','automatically pick up objects you move over',0);
 INSERT INTO options VALUES (null,'autoquiver','when firing with an empty quiver, select some suitable inventory weapon to fill the quiver',0);
 INSERT INTO options VALUES (null,'checkpoint','save game state after each level change, for possible recovery after program crash',0);
 INSERT INTO options VALUES (null,'color','user different colors for objects on the screen',0);
 INSERT INTO options VALUES (null,'confirm','ask before hitting tame or peaceful monsters',0);
 INSERT INTO options VALUES (null,'cmdassist','assist with commands',0);
 #INSERT INTO options VALUES (null,'death_explore','upon death, get asked whether or not to continue in explore mode',0);
 INSERT INTO options VALUES (null,'DECgraphics','use DEC/VT line-drawing characters for the dungeon.',0);
 INSERT INTO options VALUES (null,'eight_bit_tty','send 8-bit characters straight to the terminal. eight_bit_tty+ibmgraphics simulates windows binary',0);
 INSERT INTO options VALUES (null,'ignintr','ignore interrupt signal, including breaks',0);
 INSERT INTO options VALUES (null,'legacy',' print introductory message',0);
 INSERT INTO options VALUES (null,'lit_corridor','show a dark corridor as lit if in sight',0);
 INSERT INTO options VALUES (null,'mail','enable the mail daemon',0);
 INSERT INTO options VALUES (null,'news','print any news from the game administrator on startup',0);
 INSERT INTO options VALUES (null,'null','allow nulls to be sent to your terminal. try turning this option off (forcing nethack to use its own delay code) if moving objects seem to teleport across rooms.',0);
 INSERT INTO options VALUES (null,'number_pad','use number keys to move instead of yuhjklbn',0);
 INSERT INTO options VALUES (null,'perm_invent','keep inventory in a permanent window',0);
 INSERT INTO options VALUES (null,'prayconfirm','use confirmation prompt when #pray command is issued',0);
 INSERT INTO options VALUES (null,'pushweapon','when wielding a new weapon, put the previously wielded weapon into the secondary weapon slot',0);
 INSERT INTO options VALUES (null,'rest_on_space','count the space bar as a rest character',0);
 INSERT INTO options VALUES (null,'safe_pet','prevent you from (knowingly) attacking your pet(s)',0);
 INSERT INTO options VALUES (null,'showexp','display your accumulated experience points',0);
 INSERT INTO options VALUES (null,'showscore','display your accumulated score',0);
 INSERT INTO options VALUES (null,'silent','do not use your terminal bell sound',0);
 INSERT INTO options VALUES (null,'sortpack','group similar kinds of objects in inventory',0);
 INSERT INTO options VALUES (null,'sound','enable messages about what your character hears (note this has nothing to do with computer audio',0);
 INSERT INTO options VALUES (null,'standout','use standout for --More-- messages',0);
 INSERT INTO options VALUES (null,'time','display elapsed game time, in moves',0);
 INSERT INTO options VALUES (null,'tombstone','print tombstone when you die',0);
 INSERT INTO options VALUES (null,'toptenwin','print topten in a window rather than stdout',0);
 INSERT INTO options VALUES (null,'verbose','print more commentary during the game',0);
 INSERT INTO options VALUES (null,'align','your starting alignment- lawful, neutral, chaotic',1);
 INSERT INTO options VALUES (null,'catname','the name of your first cat',1);
 INSERT INTO options VALUES (null,'disclose','the types of information you want offered at the end of the game',1);
 INSERT INTO options VALUES (null,'dogname','the name of your first dog',1);
 INSERT INTO options VALUES (null,'dungeon','a list of symbols to be used in place of the default ones for drawing the dungeon. best to leave this alone.',1);
 INSERT INTO options VALUES (null,'effects','like dungeon, but for special effects symbols',1);
 INSERT INTO options VALUES (null,'fruit','the name of the fruit you enjoy eating',1);
 INSERT INTO options VALUES (null,'gender','your starting gender',1);
 INSERT INTO options VALUES (null,'horsename','the name of your first horse',1);
 INSERT INTO options VALUES (null,'menustyle','user interface for selection of multiple objects- traditional,combination,partial,full',1);
 INSERT INTO options VALUES (null,'monsters','like dungeon, but for monster symbols',1);
 INSERT INTO options VALUES (null,'msghistory','number of top line messages to save',1);
 INSERT INTO options VALUES (null,'name','the name of your character',1);
 INSERT INTO options VALUES (null,'objects','like dungeon, but for object symbols',1);
 INSERT INTO options VALUES (null,'packorder','list of default symbols for kinds of objects that gives the order in which your pack will be displayed',1);
 INSERT INTO options VALUES (null,'pettype','cat or dog, choose.',1);
 INSERT INTO options VALUES (null,'pickup_burden','when you pick up an item that exceeds this level (unburdened, burdened, stressed, strained, overtaxed, overloaded, you will be asked to continue',1);
 INSERT INTO options VALUES (null,'pickup_types','list of default symbols for kinds of objects to autopickup when option is on',1);
 INSERT INTO options VALUES (null,'race','starting race human, elf, dwarf, etc.',1);
 INSERT INTO options VALUES (null,'role','your starting role wiz, sam, etc.',1);
 INSERT INTO options VALUES (null,'scores','parts of the score list you wish to see when game ends.',1);
 INSERT INTO options VALUES (null,'suppress_alert','disable various version-specific warnings such as notification given for the Q command that quitting is done with #quit. use 3.3.1',1);
 INSERT INTO options VALUES (null,'traps','like dungeon, but for traps',1);
 INSERT INTO options VALUES (null,'windowtype','windowing system. probably tty',1);
 #INSERT INTO options VALUES (null,'hero_race','show your character @ as o for orc, d for dwarf, etc.',0);
 INSERT INTO options VALUES (null,'showrace','show your character @ as o for orc, d for dwarf, etc.',0);
 INSERT INTO options VALUES (null,'paranoid_quit','force typing y-e-s instead of just y when #quit-ing',0);
 INSERT INTO options VALUES (null,'showborn','show monster count - generated',0);
 INSERT INTO options VALUES (null,'extmenu','extmenu',0);
 INSERT INTO options VALUES (null,'fixinv','fix inventory',0);
 INSERT INTO options VALUES (null,'IBMgraphics','enhanced 8 bit character terminal graphics, use with eight_bit_tty',0);
 INSERT INTO options VALUES (null,'splash_screen','display initial splash screen at game startup',0);
 INSERT INTO options VALUES (null,'autodig','automatically dig without having to apply a dig-weapon each turn',0);
 INSERT INTO options VALUES (null,'help','allow help messages and verbosity during the game',0);
 INSERT INTO options VALUES (null,'hilite_pet','highlight your tame pets using reverse video graphics for easy locating',0);
 #INSERT INTO options VALUES (null,'menucolors','allow menu items to have multiple\ncolors',0);
 INSERT INTO options VALUES (null,'msg_window','allow a popup buffer of messages governed by msghistory',0);
 INSERT INTO options VALUES (null,'sparkle','enable extra special effects for terminal graphics',0);
 INSERT INTO options VALUES (null,'use_inverse','enable inverse video - use this with hilite_pet',0);
 INSERT INTO options VALUES (null,'travel','travel',0);
 INSERT INTO options VALUES (null,'lootabc','lootabc',0);
