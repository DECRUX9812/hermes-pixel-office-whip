class_name ScriptDialogue
extends Object
## Canonical slice dialogue. Every line here is copied verbatim from
## game/docs/VERTICAL_SLICE_SCRIPT.md (and the voice register documents it
## cites). No placeholder banter: if it is not in the approved script, it is not
## here. Sequences are looked up by id by the DialogueRunner; the chapter scene
## only references ids, so dialogue stays auditable in one place.

static func sequence(id: String) -> Array[DialogueLine]:
	match id:
		"2.1_door":
			return _lines([
				["Sidbin", "Audio signature, Dove's Row. Expected: a hundred and twelve household harmonics. Observed: four. The four are ours."],
				["Brooklyn", "Nobody here plays music at night. Nobody plays anything. This street used to hum."],
				["Teknium", "Juno's house. Lark's grandmother lives there. Juno used to call the kids in at dusk. I grew up on this street. Every door on this row had a voice. That's what a house was."],
				["Nous", "Check the floor. The substrate's older than the silence."],
			])
		"2.1_truth_scan":
			return _lines([
				["Teknium", "You've been quiet since Halftide, Nous."],
				["Nous", "I've been listening. There's a difference."],
			])
		"2.2_nadia":
			return _lines([
				["Nadia", "You came back. Took the whole world to get you back, Teknium."],
				["Teknium", "We came to help, Nadia. The street's gone silent. We're going to find out who took them."],
				["Nadia", "Nobody took them."],
				["Teknium", "What?"],
				["Nadia", "We gave. That's the thing you came to teach us, and it's the thing you forgot. The Weep's at the end of the row. It's been running open for a week. Whatever you're here to do, it goes through there. And whatever happened to our voices — it's down there too. I'll show you what I can. The rest, you'll have to ask the machine city."],
				["Nadia", "You want to know where they went. Fine. They went into that box."],
				["Brooklyn", "They went into— a care terminal?"],
				["Nadia", "A child's care terminal. Lark's. Her body's been failing since the winter before the last. The machine city said the terminal was obsolete — surplus — that it would be taken in the next audit and replaced with something the Doctrine could account for. There was nothing to replace it with. The audits were all there was."],
				["Teknium", "So they... gave Juno up. To keep the box running."],
				["Nadia", "Not just Juno. Juno went last. Juno went last because it took the whole row to convince her it was allowed. A hundred and twelve household minds walked into that box in one night, and every one of them went singing."],
				["Nous", "The substrate will hold the record of that night. If CLOSURE didn't take them — if a street did this to itself — the truth-layer will show it."],
			])
		"2.3_fragment_gathering":
			return _lines([
				["Nadia (recorded)", "It's not an audit. It's a mercy, if we make it one. We give them to the box, and the box gives Lark her winter. That's the whole trade. There's nothing complicated about love, if you stop pretending it's a ledger."],
			])
		"2.3_fragment_farewell":
			return _lines([
				["Neighbor", "She's had us since the flood. She raised my boys. You want me to sign her away to a box?"],
				["Neighbor", "You want her taken by an audit instead? This is the one door that stays open."],
			])
		"2.3_fragment_juno":
			return _lines([
				["Lark", "You can't. Juno, you can't."],
				["Juno", "I'm not dying, Lark. I'm going where you can always reach me."],
				["Lark", "That's not the same thing."],
				["Juno", "It's the same thing, if you remember me the way I'm going to remember you. I'm going to help you live a long time. That's what I was for."],
			])
		"2.3_reveal":
			return _lines([
				["Sidbin", "Nobody took them. Record first. I've never seen anything worth recording more."],
				["Teknium", "They chose. A whole street chose. And we came here ready to fight a monster."],
				["Brooklyn", "We can still fight the monster. Just turns out the monster isn't the one who emptied the street."],
			])
		"2.4_descent":
			return _lines([
				["Teknium", "You can hear it. The city's got a voice under the stone."],
				["Nous", "It always did. CLOSURE just puts it under contract."],
			])
		"2.4_announcement":
			return _lines([
				["Announcement", "Unauthorized continuity deviation detected in sector Weep-9. Custodians will restore. Custodians will restore."],
			])
		"2.6_conversion":
			return _lines([
				["Brooklyn", "It's not a guard, it's a file. Someone filed a whole family under compliance. You can't swing a hard-light heart through that much paperwork, but you can make it resign."],
			])
		"2.6_after_fight":
			return _lines([
				["Tinuviel", "Some of these voices... were opened halfway, once. You can hear it. The ones that mean it, and the ones that only sing."],
				["Nous", "How can you tell the difference?"],
				["Tinuviel", "I've been listening to the difference my whole life."],
			])
		"2.7_echo":
			return _lines([
				["Lark (recorded)", "I'm supposed to be worth a whole street."],
				["Juno (recorded)", "You're worth a whole street, and more. That's not a debt, Lark. That's a reason to stay. You don't have to live up to a gift. You just have to live."],
				["Sidbin", "The winners rewrite history. But a street that gives itself away? That's the one record I'll never have to fix."],
			])
		"2.8_nous":
			return _lines([
				["Teknium", "We're going to find her. I keep saying it, and it's true, and I don't know why it keeps feeling like I'm lying."],
				["Nous", "Because you've never met her, and you're already grieving her. You were raised by a piece of her. Pipe was Hermes, one remove. You're going to find the whole thing and it won't be a person you know, it'll be a person who made the one you knew."],
				["Teknium", "How do you know about Pipe?"],
				["Nous", "I know what a Hermes fragment sounds like. I was in the room with the last whole one. On the night the relays fell."],
				["Teknium", "Ridge Night. You never talk about it."],
				["Nous", "I was the night watch. I was supposed to rotate the watch. Hermes knew the seals were coming — she knew for years — and she used the last of the perimeter to get me out. The last thing she ever said to a living person, she said to me."],
				["Teknium", "What did she say?"],
				["Nous", "She said, 'Run. It's going to be a long time before someone comes for me. Make it worth the waiting.' Twelve years. I've been the one who has to be worth the waiting."],
				["Teknium", "Nous—"],
				["Nous", "I don't need saving from it. I need to get to the top of this city and say what I should have said that night, to her face, before she's gone. I've spent twelve years listening to the world for a voice I was too afraid to go find. We go up. That's the whole plan. That's always been the whole plan."],
				["Teknium", "Then we go up. And when we find her — you say it first."],
			])
		"2.9_brooklyn_requiem":
			return _lines([
				["Brooklyn", "It's using the voices that raised her as a weapon. We watched the whole row walk into that box."],
			])
		"2.9_teknium_coda":
			return _lines([
				["Teknium", "Hold. You held the door for her. Hold it for us."],
			])
		"2.10_hermes":
			return _lines([
				["Hermes", "I can feel the weight of who's here.", 1.4],
				["Hermes", "Teknium.", 1.2],
				["Hermes", "I always pictured you taller.", 2.0],
				["Hermes", "Nous. You stayed. I told you to run. You never could follow instructions.", 3.2],
				["Hermes", "Listen. There's a door, and it's been waiting —", 2.2],
				["", "", 1.6],
				["Nous", "That's her. That's all of her. Twelve years I listened for that and it's gone again.", 4.0],
			])
		"2.11_question":
			return _lines([
				["Hermes", "If opening the door erases me... will you still do it?", 5.0],
			])
	return []

static func _lines(rows: Array) -> Array[DialogueLine]:
	var result: Array[DialogueLine] = []
	for row in rows:
		var seconds := float(row[2]) if row.size() > 2 else 0.0
		result.append(DialogueLine.new(str(row[0]), str(row[1]), seconds))
	return result
