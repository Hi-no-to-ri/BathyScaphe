FasdUAS 1.101.10   ��   ��    k             l      �� ��    L F
  BoardWarrior.scpt
  BathyScaphe 1.5 Starlight Breaker
  2007-06-04
       	  l     ������  ��   	  
  
 i         I      �� ���� 0 make_default_list        o      ���� 0 plpath plPath      o      ���� 0 	ftoolpath 	ftoolPath      o      ���� 0 wherefolder     ��  o      ���� (0 downloadedhtmlpath downloadedhtmlPath��  ��    k     V       r         m               o      ���� 0 myresult        l   ������  ��        r       !   n    	 " # " 1    	��
�� 
strq # l    $�� $ b     % & % o    ���� 0 wherefolder   & m     ' '  /board_default.plist   ��   ! o      ���� 0 defaultplist defaultPlist   ( ) ( r     * + * l    ,�� , I   �� -��
�� .sysoexecTEXT���     TEXT - b     . / . b     0 1 0 m     2 2  find     1 l    3�� 3 n     4 5 4 1    ��
�� 
strq 5 o    ���� 0 wherefolder  ��   / m     6 6    -name board_default.plist   ��  ��   + o      ���� 0 ifplistexist   )  7 8 7 Z    3 9 :���� 9 l    ;�� ; >    < = < o    ���� 0 ifplistexist   = m     > >      ��   : l    / ? @ ? I    /�� A��
�� .sysoexecTEXT���     TEXT A b     + B C B b     % D E D b     # F G F m     ! H H 	 cp     G o   ! "���� 0 defaultplist defaultPlist E m   # $ I I       C n   % * J K J 1   ( *��
�� 
strq K l  % ( L�� L b   % ( M N M o   % &���� 0 wherefolder   N m   & ' O O  /board_default~.plist   ��  ��   @    file exists, so backup it   ��  ��   8  P Q P l  4 4������  ��   Q  R S R r   4 K T U T b   4 I V W V b   4 G X Y X b   4 E Z [ Z b   4 A \ ] \ b   4 ? ^ _ ^ b   4 ; ` a ` b   4 9 b c b m   4 5 d d  perl     c l  5 8 e�� e n   5 8 f g f 1   6 8��
�� 
strq g o   5 6���� 0 plpath plPath��   a m   9 : h h       _ l  ; > i�� i n   ; > j k j 1   < >��
�� 
strq k o   ; <���� (0 downloadedhtmlpath downloadedhtmlPath��   ] m   ? @ l l       [ l  A D m�� m n   A D n o n 1   B D��
�� 
strq o o   A B���� 0 	ftoolpath 	ftoolPath��   Y m   E F p p 	  >     W o   G H���� 0 defaultplist defaultPlist U o      ���� 0 myscript   S  q r q r   L S s t s I  L Q�� u��
�� .sysoexecTEXT���     TEXT u o   L M���� 0 myscript  ��   t o      ���� 0 myresult   r  v�� v L   T V w w o   T U���� 0 myresult  ��     x y x l     ������  ��   y  z { z i     | } | I      �� ~���� 0 update_user_list   ~   �  o      ���� 0 rosettapath   �  � � � o      ���� 0 wherefolder   �  ��� � o      ���� (0 downloadedhtmlpath downloadedhtmlPath��  ��   } k     i � �  � � � r      � � � m      � �       � o      ���� 0 myresult   �  � � � l   ������  ��   �  � � � r     � � � n    	 � � � 1    	��
�� 
strq � l    ��� � b     � � � o    ���� 0 wherefolder   � m     � �  /board.plist   ��   � o      ���� 0 	argvposix 	argvPOSIX �  � � � r     � � � l    ��� � I   �� ���
�� .sysoexecTEXT���     TEXT � b     � � � b     � � � m     � �  find     � l    ��� � n     � � � 1    ��
�� 
strq � o    ���� 0 wherefolder  ��   � m     � �   -name board.plist   ��  ��   � o      ���� 0 ifplistexist   �  � � � Z    & � ����� � l    ��� � =    � � � o    ���� 0 ifplistexist   � m     � �      ��   � l    " � � � L     " � � m     !��
�� 
null �   not need to sync   ��  ��   �  � � � l  ' '������  ��   �  � � � r   ' , � � � n   ' * � � � 1   ( *��
�� 
strq � o   ' (���� 0 rosettapath   � o      ���� 0 plpath plPath �  � � � l  - -������  ��   �  � � � I  - <�� ���
�� .sysoexecTEXT���     TEXT � b   - 8 � � � b   - 2 � � � b   - 0 � � � m   - . � � 	 cp     � o   . /���� 0 	argvposix 	argvPOSIX � m   0 1 � �       � n   2 7 � � � 1   5 7��
�� 
strq � l  2 5 ��� � b   2 5 � � � o   2 3���� 0 wherefolder   � m   3 4 � �  /board~.plist   ��  ��   �  � � � r   = L � � � b   = J � � � b   = H � � � b   = F � � � b   = B � � � b   = @ � � � m   = > � �  perl     � o   > ?���� 0 plpath plPath � m   @ A � �       � l  B E ��� � n   B E � � � 1   C E��
�� 
strq � o   B C���� (0 downloadedhtmlpath downloadedhtmlPath��   � m   F G � �       � o   H I���� 0 	argvposix 	argvPOSIX � o      ���� 0 myscript   �  � � � r   M T � � � I  M R�� ���
�� .sysoexecTEXT���     TEXT � o   M N���� 0 myscript  ��   � o      ���� 0 myresult   �  � � � Z   U b � ����� � =  U X � � � o   U V���� 0 myresult   � m   V W � �       � r   [ ^ � � � m   [ \ � �  No URLs are modified.    � o      ���� 0 myresult  ��  ��   �  � � � l  c c������  ��   �  ��� � L   c i � � c   c h � � � o   c d���� 0 myresult   � m   d g��
�� 
utxt��   {  ��� � l     ������  ��  ��       �� � � ���   � ������ 0 make_default_list  �� 0 update_user_list   � �� ���� � ����� 0 make_default_list  �� �� ���  �  ���������� 0 plpath plPath�� 0 	ftoolpath 	ftoolPath�� 0 wherefolder  �� (0 downloadedhtmlpath downloadedhtmlPath��   � ��~�}�|�{�z�y�x� 0 plpath plPath�~ 0 	ftoolpath 	ftoolPath�} 0 wherefolder  �| (0 downloadedhtmlpath downloadedhtmlPath�{ 0 myresult  �z 0 defaultplist defaultPlist�y 0 ifplistexist  �x 0 myscript   �   '�w 2 6�v > H I O d h l p
�w 
strq
�v .sysoexecTEXT���     TEXT�� W�E�O��%�,E�O��,%�%j E�O�� �%�%��%�,%j Y hO��,%�%��,%�%��,%�%�%E�O�j E�O� � �u }�t�s � ��r�u 0 update_user_list  �t �q ��q  �  �p�o�n�p 0 rosettapath  �o 0 wherefolder  �n (0 downloadedhtmlpath downloadedhtmlPath�s   � �m�l�k�j�i�h�g�f�m 0 rosettapath  �l 0 wherefolder  �k (0 downloadedhtmlpath downloadedhtmlPath�j 0 myresult  �i 0 	argvposix 	argvPOSIX�h 0 ifplistexist  �g 0 plpath plPath�f 0 myscript   �  � ��e � ��d ��c � � � � � � � ��b
�e 
strq
�d .sysoexecTEXT���     TEXT
�c 
null
�b 
utxt�r j�E�O��%�,E�O��,%�%j E�O��  �Y hO��,E�O�%�%��%�,%j O�%�%��,%�%�%E�O�j E�O��  �E�Y hO�a & ascr  ��ޭ