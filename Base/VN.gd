extends Node2D

var fullscene = [
]

var scenepos = 0
var commandpos = 1 #If 1, text is scrolling. If 2, can go to next command.
var framepos = 0 #for scrolling text, stuff that requires held inputs
var framepos_max = 60 #the frames needed to fully show an animation/text scroll
var gametime = 0 #for the overcomplicated input system I lazily copied

var latesttextbox = 'def'
var latestspeaker = 'def'
var latestwindow = 'def'

var unskippabletimer = 0




#to do-
#sequence;[number];[length];[skip] will make the next [number] commands a singular animation that may be clicked through.
	  #if [skip] is true/1, the animation will be unskippable.
	  

#animation;[variable];[frame length];[endpoint] will animate a specific variable. The endpoint (in frames) is the final value,
#which MAY be skipped to if this animation is part of a sequence. Otherwise, it will change regardless of framepos. 








func _ready():
	load_nextfile()
	initialize_buttons(input_init)
	def_textbox()
	
	
	read_commands()


	#Resets the scene and switches to the file
func switch2file(filenamee):
	global.nextfile = filenamee
	get_tree().reload_current_scene()



	#Appends the file to your current scene. Why would you need this? 
func append_file(filenamee):
	pass



const singleline_exceptions = []

func parse_file(filenamee): #the actual parser code
	print ("Starting new script " + filenamee + "...")
	var loadedfile = File.new()
	loadedfile.open("res://Scripts/" + filenamee + ".vnomad", File.READ)
	var perline = loadedfile.get_as_text().split("\n")
	var newcontent = []
	for line in perline:
		var lineaslist = line.split(";")
		if len(lineaslist) == 1: #If there's only text in the line with no semicolons, it will be treated as printed text
			if line.split(";")[0]  in singleline_exceptions: #unless they're these specific commands, in which case add them as is
				newcontent.append(lineaslist)
			else:
				var prunedline = dumbassfuckingforloop(line,[" ","	"])
				if prunedline != "":
					if prunedline[0] != "#":
						newcontent.append(["p",lineaslist[0]]) #empty lines get ignored
				
		else:
			newcontent.append(lineaslist)
	
	for x in newcontent:
		fullscene.append(x)
	
	
	loadedfile.close()


func dumbassfuckingforloop(dastring,dacharls): #removes a character from the string
	var daresult = ''
	for chr in dastring:
		if not chr in dacharls:
			daresult = daresult + chr
	return daresult


func load_nextfile():
	scenepos = 0
	commandpos = 1
	framepos = 0
	fullscene = []
	parse_file(global.nextfile)
	
	
	
	
	latestspeaker = 'def'
	latesttextbox = 'def'
	latestwindow = 'def'





func create_textbox(namae,pos,bganim,boxanim='def'):
	var textbox_load = load('res://Base/Textbox.tscn')
	var textbox = textbox_load.instance()
	for x in get_children():
		if comparename(x.name,'Textbox'):
			if x.textboxname == namae and x != textbox:
				textbox.textboxname = namae + "+"
			else: textbox.textboxname = namae
	add_child(textbox)
	textbox.position = pos
	textbox.get_node('scrollingBG').animation = bganim
	
	
	#When a textbox is created, by default the next text you print out will belong to it
	latesttextbox = textbox.textboxname



func create_window(namae,anim,pos,type,typedata=''):
	var window_load = load('res://Base/Window.tscn')
	var window = window_load.instance()
	add_child(window)
	for x in get_children():
		if x.name.substr(0,6) == 'Window' or x.name.substr(0,7) == '@Window':
			if x.windowname == namae and x != window:
				window.windowname = namae + "+"
			else: window.windowname = namae
	window.position = pos
	window.windowtype = type
	window.get_node('windowsprite').animation = anim
	latestwindow = window.windowname
	if typedata != '': window.get_node('windowtext').text = typedata #sets text if it's a Speaker type window
	#The only use for giving a window a speaker type is so that textbox removal would remove the speaker box as well

func create_speaker(namae):
	var realpos = Vector2(0,0)
	if len(fullscene[scenepos]) > 4:
		realpos = Vector2(fullscene[scenepos][3],fullscene[scenepos][4])
	else:
		var usedtextbox = []
		var TextboxFound = false
		for x in get_children():
			if comparename(x.name,'Textbox'):
				if x.textboxname == namae:
					TextboxFound = true
					usedtextbox = x
		if TextboxFound:
			realpos = usedtextbox.position + Vector2(4,-52)
		else: #will attach itself to the first textbox it can find, SHOULD NOT HAPPEN
			for x in get_children():
				if comparename(x.name,'Textbox'):
					print ('Speaker box has been attached to the first textbox it could find. This should not happen.')
					realpos = x.position + Vector2(4,-52)
	create_window(namae,'speaker',realpos,'','')

func def_textbox():
	create_textbox('def',Vector2(500,500),'def')

func jump(flag):
	for x in range(len(fullscene)):
		if fullscene[x][0] in ['flag','f','	flag',' f']:
			if fullscene[x][1] == flag:
				scenepos = x
				read_commands()
				break
			else: advance() #if flag doesn't exist just go forward



func advance():
	framepos=0
	scenepos+=1
	commandpos = 1
	read_commands()

func click():
	if commandpos == 1:
		scrollskip()
	elif commandpos == 2:
		advance()

func scrollskip():
	framepos = framepos_max
	commandpos = 2



func read_commands():
	
	if scenepos >= len(fullscene): #prevents a crash
		print ('Novel End')
		return

	if curcommandL(['speaker','s']):
		var usedwindow = []
		if len(fullscene[scenepos]) > 2:
			var WindowExists = false
			for x in get_children():
				if comparename(x.name,'Window'):
					if x.windowname == fullscene[scenepos][2]:
						WindowExists = true
						usedwindow = x
			if not WindowExists:
				create_speaker(fullscene[scenepos][2]) #pos will be changed later
				usedwindow = findwindow(fullscene[scenepos][2])
		else:
			if latestspeaker == '':
				create_speaker('def')
				usedwindow = findwindow('def')
			else:
				if not findwindow(latestspeaker):
					create_speaker(latestspeaker)
				usedwindow = findwindow(latestspeaker)
		latestspeaker = usedwindow.windowname
		latestwindow = usedwindow.windowname
		usedwindow.get_node('windowtext').text = fullscene[scenepos][1]
		advance()
	
	#if curcommandL(['ps','playsound']):
#		var usedwindow = []
#		if len(fullscene[scenepos]) > 2:
#			var WindowExists = false
#		var PlaySound = fullscene[scenepos + 1]
#		var LoadedSound = PlaySound + ".mp3"
#		$sound.play(LoadedSound)

	
	if curcommandL(['p','print']):
		commandpos = 1
		var textbox = []
		if len(fullscene[scenepos]) > 2:
			textbox = findtextbox(fullscene[scenepos][2])
			textbox.fulltext = fullscene[scenepos][1]
			latesttextbox = fullscene[scenepos][2]
		else:
			textbox = findtextbox(latesttextbox)
			textbox.fulltext = fullscene[scenepos][1]
		textbox.latestposition = scenepos
		framepos_max = int(len(textbox.fulltext)/global.settings['textspeed'])+1

	if curcommandL(['pskip','printskip']): #prints text but doesn't scroll it and skips to the next command
		var textbox = []
		if len(fullscene[scenepos]) > 2:
			textbox = findtextbox(fullscene[scenepos][2])
			textbox.fulltext = fullscene[scenepos][1]
			textbox.get_node('scrollingText').text = fullscene[scenepos][1]
			
			latesttextbox = fullscene[scenepos][2]
		else:
			textbox = findtextbox(latesttextbox)
			textbox.fulltext = fullscene[scenepos][1]
			textbox.get_node('scrollingText').text = fullscene[scenepos][1]
		advance()
	if curcommandL(['newtextbox','create_textbox','createtextbox','nt']):
		if curlen() > 4:
			create_textbox(fullscene[scenepos][1],Vector2(cur(2),cur(3)),cur(4))
		else:
			create_textbox(fullscene[scenepos][1],Vector2(fullscene[scenepos][2],fullscene[scenepos][3]),'def')
		#insert 9patch box name here

		advance()
	if curcommandL(['removetextbox','rt']):
		findtextbox(fullscene[scenepos][1]).queue_free()
		if len(fullscene[scenepos]) > 2:
			if not fullscene[scenepos][2] == 'leavespeaker':
				findwindow(fullscene[scenepos][1]).queue_free()
		else:
			findwindow(fullscene[scenepos][1]).queue_free() #What the fuck why doesn't this crash the game?
		advance()
	if curcommandL(['newwindow','create_window','createwindow','nw']):
		create_window(cur(1),cur(2),Vector2(int(cur(3)), int(cur(4))),'standard','')
		if curlen() > 5: findwindow(cur(1)).windowtype = cur(5) #windowtype
		if curlen() > 6: findwindow(cur(1)).windowtypedata = cur(6) #type data
		advance()
	if curcommandL(['removewindow','rw']):
		findwindow(cur(1)).queue_free()
		advance()
	if curcommand('setanim'): #changes the windowsprite animation of a specific window, or the latest window if not specified.
		if curlen() > 2: #untested
			findwindow(fullscene[scenepos][2]).get_node('windowsprite').animation = fullscene[scenepos][1]
			latestwindow = cur(2)
		else:
			findwindow(latestwindow).get_node('windowsprite').animation = fullscene[scenepos][1]
		
		advance()
	if curcommandL(['setposition','setpos']): 
		if curlen() > 3:
			findwindow(cur(3)).position = Vector2(cur(1),cur(2))
			latestwindow = cur(3)
		else:
			findwindow(latestwindow).position = Vector2(cur(1),cur(2))
		advance()
	if curcommand('loadfile'):
		switch2file(cur(1))
	if curcommandL(['flag','f','	flag',' f']):
		advance()
	if curcommandL(['jump','j']): 
		jump(cur(1))
	



func curlen(): return(len(fullscene[scenepos])) #returns the length of the command you're in
func cur(inp): return (fullscene[scenepos][inp]) #returns the current scene position at the index you input



func curcommand(input): #checks the first entry in the current scene position in fullscene
	if len(fullscene[scenepos]) > 0: #this shouldn't happen
		if fullscene[scenepos][0] == input:
			return true
		else: return false
func curcommandL(listinput): #a version of curcommand that checks a list
	if len(fullscene[scenepos]) > 0: #this shouldn't happen
		if fullscene[scenepos][0] in listinput:
			return true
		else: return false


func comparename(compared,namae):
	if compared.substr(0,len(namae)) == namae:
		return true
	else:
		if compared.substr(0,len(namae)+1) == ("@" + namae):
			return true

func findtextbox(input):
	for x in get_children():
		if x.name.substr(0,7) == 'Textbox' or x.name.substr(0,8) == '@Textbox':
			if x.textboxname == input:
				return x
	for y in get_children(): #exception handling, if it can't find the given textbox then use the default one
		if y.name.substr(0,7) == 'Textbox':
			if y.textboxname == 'def':
				return y

func findwindow(input):
	for x in get_children():
		if comparename(x.name,"Window"): #same thing as the same line in findtextbox(), just a shorthand
			if x.windowname == input:
				return x
	for y in get_children(): #removes first window it finds if the specified window isn't found
		if y.name.substr(0,6) == 'Window' or y.name.substr(0,7) == '@Window':
			print ("DEBUG!!!   enginename= " + str(y.name) + ".     windowname= " + str(y.windowname) + \
			". If you see this, you probably messed something up when writing the script file. ")
			return y



func _physics_process(delta):
	base_setanalog()
	writebuffer()
	controls()
	if inputjustpressed(up):
		print (get_children())
	if inputjustpressed(left):
		print (fullscene)
	if inputjustpressed(down):
		var listofshit = []
		for x in get_children():
			if comparename(x.name,'Window'):
				listofshit.append("!!" + x.windowname + "!!")
		print (str(listofshit) + "      --" + latestspeaker + "--    latestwindow= -" + latestwindow + "-")
	gametime+=1
	if framepos >= framepos_max and commandpos == 1:
		commandpos = 2
	framepos+=1



		##INPUTS

#the actual relevant stuff


func controls():
	if inputjustpressed(accept) and gametime != 0:
		click()
	if commandpos == 1 and inputheld(skipscrolling):
		scrollskip()









#This is the Blacklight input system, which has no weaknesses..
#It's done for a fighting game so obviously it's too detailed for a VN but I'm too lazy to remove stuff from it
#And I'm for sure not gonna do this shit from scratch

#Buttons
var up = ''
var down = '' 
var left = ''
var right = ''
var jump = ''
var accept = ''
var skipscrolling = '' 
var attackC = '' 
var attackD = '' 
var attackE = ''
var attackF = ''
var dodge = ''
var grab = ''
var cstickup = ''
var cstickdown = ''
var cstickleft = ''
var cstickright = ''
var uptaunt = ''
var sidetaunt = ''
var downtaunt = ''
const input_init = ['up','down','left','right','','accept','skipscrolling','','','','', 
	'','','','','','','','','',
	]
func initialize_buttons(buttonset):
	up = buttonset[0]
	down = buttonset[1]
	left = buttonset[2]
	right = buttonset[3]
	jump = buttonset[4]
	accept = buttonset[5]
	skipscrolling = buttonset[6]
	attackC = buttonset[7]
	attackD = buttonset[8]
	attackE = buttonset[9]
	attackF = buttonset[10]
	dodge = buttonset[11]
	grab = buttonset[12]
	cstickup = buttonset[13]
	cstickdown = buttonset[14]
	cstickleft = buttonset[15]
	cstickright = buttonset[16]
	uptaunt = buttonset[17]
	sidetaunt = buttonset[18]
	downtaunt = buttonset[19]
	currentreplay = {
	'analog' : [],
	up : [] ,
	down : [],
	left : [], 
	right : [],
	jump : [],
	accept : [],
	skipscrolling : [],
	attackC : [],
	attackD : [],
	attackE : [],
	attackF : [],
	dodge : [],
	grab : [],
	cstickup : [],
	cstickdown : [],
	cstickleft : [],
	cstickright : [],
	uptaunt : [],
	sidetaunt : [],
	downtaunt : [],
}
	buffer = [
[buttonset[0],1,9000,9000],
[buttonset[1],1,9000,9000],
[buttonset[2],1,9000,9000],
[buttonset[3],1,9000,9000],
[buttonset[4],1,9000,9000],
[buttonset[5],1,9000,9000],
[buttonset[6],1,9000,9000],
[buttonset[7],1,9000,9000],
[buttonset[8],1,9000,9000],
[buttonset[9],1,9000,9000],
[buttonset[10],1,9000,9000],
[buttonset[11],1,9000,9000],
[buttonset[12],1,9000,9000],
[buttonset[13],1,9000,9000],
[buttonset[14],1,9000,9000],
[buttonset[15],1,9000,9000],
[buttonset[16],1,9000,9000],
[buttonset[17],1,9000,9000],
[buttonset[18],1,9000,9000],
[buttonset[19],1,9000,9000],
]


#x[0] = input name
#x[1] = frames the input has been held
#x[2] = frames since this button has been pressed last (standard buffer)
#x[3] = frames since this button has been released
var buffer = [
[up,0,9000,9000],
[down,0,9000,9000],
[left,0,9000,9000],
[right,0,9000,9000],
[jump,0,9000,9000],
[accept,0,9000,9000],
[skipscrolling,0,9000,9000],
[attackC,0,9000,9000],
[attackD,0,9000,9000],
[attackE,0,9000,9000],
[attackF,0,9000,9000],
[dodge,0,9000,9000],
[grab,0,9000,9000],
[cstickup,0,9000,9000],
[cstickdown,0,9000,9000],
[cstickleft,0,9000,9000],
[cstickright,0,9000,9000],
[uptaunt,0,9000,9000],
[sidetaunt,0,9000,9000],
[downtaunt,0,9000,9000],
]
var pressbuffer = 4
var releasebuffer = 4
#After inputs come into the engine, EVERY input should be checked by using the data in the buffer variable,
#or functions/vars that get their data on inputs from buffer, like motionqueue. 
#buffer itself gets input data from base_inputheld(), which uses either player inputs,
#or recorded input data from replays, or potentially netcode(I am quite uninformed on netcode, though). 
#To get inputs for the state machine and such, use the following functions that use buffer var:
#	inputheld() is self_explanatory.
#	inputpressedbuffer() checks for a pressbuffer.
#	inputreleasedbuffer() has its own buffer
			# ^^^ both of these were renamed for this project so people don't accidentally use buffer input checks 
#	inputjustreleased() (no input buffer)
#	inputjustpressed() (checks for an input press, has no input buffer)
#   inputpressedbuffer() and inputreleasedbuffer() have two optional params- custombuffer and prevstate.
#	custombuffer lets you specify a specific frame amount. If you're not sure, then set it to pressbuffer.
#	prevstate lets you ignore the input if the previous state is the same state as the one specified.
var currentreplay = {
	'analog' : [],
	up : [] ,
	down : [],
	left : [], 
	right : [],
	jump : [],
	accept : [],
	skipscrolling : [],
	attackC : [],
	attackD : [],
	attackE : [],
	attackF : [],
	dodge : [],
	grab : [],
	cstickup : [],
	cstickdown : [],
	cstickleft : [],
	cstickright : [],
	uptaunt : [],
	sidetaunt : [],
	downtaunt : [],
}
var controllable = true #false when replay
var analogstick = Vector2(128,128)
var analogstick_prev = Vector2(128,128)
var analog_deadzone = 24 #should probably be the same as analog_tilt
var analog_tilt = 24 #how much distance you need for the game to consider something a tilt input rather than neutral
var analog_smash = 64 #how much distance the stick has to travel to be considered an u/d/l/r/ or smash input
func analogconvert(floatL,floatR,floatD,floatU):
#Godot returns analog "strength" of actions as a float going from 0 to 1.
#This function converts up/down/left/right inputs into a Vector2() which represents both axes as 256-bit digits.
	var analogX = 0
	var analogY = 0
	if floatL > floatR:
		analogX = 128 - 128*floatL 
	elif floatR > floatL:
		analogX = 128 + 127*floatR
	else: #if digital users input both left and right, go neutral
		analogX = 128
	#same thing for y axis
	if floatD > floatU:
		analogY = 128 - 128*floatD
	elif floatU >= floatD:
		analogY = 128 + 127*floatU
	#return finished calculations
	return Vector2(round(analogX),round(analogY))
func analogdeadzone(stick,zone): #applies a center deadzone to a stick value
	if not( stick.x <= 128-zone or stick.x >= 128+zone):
		if not (stick.y <= 128-zone or stick.y >= 128+zone):
			return Vector2(128,128)
	return stick
func analogdeadzone_axis(stick,zone): #applies an axis deadzone, like a cross instead of a square
	var resultstick = Vector2(128,128)
	if not( stick.x <= 128-zone or stick.x >= 128+zone):
		resultstick.x = 128
	else: resultstick.x = stick.x
	if not (stick.y <= 128-zone or stick.y >= 128+zone):
		resultstick.y = 128
	else: resultstick.y = stick.y
	return resultstick
func base_setanalog(): #sets the analogstick var to 0-255 values every frame w a deadzone
		analogstick_prev = analogstick #For SDI
		if controllable:
			if left != "": #prevents error spam if a character doesn't have control stick inputs.
				analogstick = analogconvert(Input.get_action_strength(left),Input.get_action_strength(right),Input.get_action_strength(down),Input.get_action_strength(up))
			analogstick = analogdeadzone_axis(analogstick,analog_deadzone) #Only really needed for airdodging and DI
			if currentreplay['analog'] == []:
				currentreplay['analog'].append([gametime, analogstick.x, analogstick.y])
			else:
				if [currentreplay['analog'][-1][1],currentreplay['analog'][-1][2]] != [analogstick.x,analogstick.y]:
					currentreplay['analog'].append([gametime, analogstick.x, analogstick.y])
		else: #if it's a replay
			for x in currentreplay['analog']:
				if x[0] == gametime:
					analogstick = Vector2(x[1],x[2])
func base_inputheld(inp):
	if controllable:
		if inp != "": #this line prevents massive lag in interpreter when a button isn't set. 
			if Input.is_action_pressed(inp):
				if inp in [up,down,left,right]:
					if analogstick != Vector2(128,128):
	#this code will break if there is no deadzone and analog_smash is at a small or 0 value. Please don't do that you have no reason to
#The center is 128,128 like Melee.
						if inp == up:
							if analogstick.y <= 255 and analogstick.y >= 128+analog_smash:
								return true
						if inp == down:
							if analogstick.y >= 0 and analogstick.y <= 128-analog_smash: #might take away the equals at the later check
								return true
						if inp == left:
							if analogstick.x >= 0 and analogstick.x <= 128-analog_smash:
								return true
						if inp == right:
							if analogstick.x <= 255 and analogstick.x >= 128+analog_smash:
								return true
				elif Input.get_action_strength(inp) >= 0.5: #If you use an analog stick for a button input,
					return true # you need to press it at least halfway like the u/d/l/r inputs above
				else: return false
			else: return false
	else:
		for x in currentreplay:
			if x == inp:
				for n in currentreplay[x]:
					if n[1] > gametime and n[0] <= gametime:
						return true
func writebuffer():
	if true: #lol
		for x in buffer:
			x[2]+=1
			x[3]+=1
			if base_inputheld(x[0]) and x[1] == 0:
				x[2]=0
				currentreplay[x[0]].append([gametime,0])
			if base_inputheld(x[0]):
				x[1]+=1
			if not base_inputheld(x[0]) and x[1] != 0:
				x[1]=0
				x[3]=0
				if currentreplay[x[0]] != []: currentreplay[x[0]][-1][1] = gametime
func inputheld(inp,below=900000000,above=0): #button held. pretty simple
	for x in buffer:
		if x[0] == inp:
			if x[1] > above and x[1] <= below:
				return true
			else: return false
func inputpressedbuffer(inp,custombuffer=pressbuffer,erase=true): 
	for x in buffer:
		if x[0] == inp:
			if x[2] <= custombuffer:
				if true: #used to be prevstate
					if erase: x[2] = custombuffer #can't use the same input to do 2 different actions. Please do not change erase if you don't know what you're doing.
					return true 
				else: return false
			else: return false
func inputreleased(inp,custombuffer=releasebuffer):
	for x in buffer:
		if x[0] == inp:
			if x[3] <= custombuffer:
				if true:
					x[3] = custombuffer #can't use the same input to do two different (release) actions.
					return true 
				else: return false
			else: return false
func inputjustpressed(inp): #button pressed this frame, no buffer
	for x in buffer:
		if x[0] == inp:
			if x[2] == 0:
				return true
			else: return false
func inputjustreleased(inp): #button released this frame, no buffer
	for x in buffer:
		if x[0] == inp:
			if x[3] == 0:
				return true
			else: return false

