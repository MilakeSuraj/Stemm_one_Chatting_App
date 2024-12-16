import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../api/apis.dart';
import '../helper/dialogs.dart';
import '../main.dart';
import '../models/chat_user.dart';
import '../widgets/chat_user_card.dart';
import '../widgets/profile_image.dart';
import 'profile_screen.dart';

//home screen -- where all available contacts are shown
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // for storing all users
  List<ChatUser> _list = [];

  // for storing searched items
  final List<ChatUser> _searchList = [];
  // for storing search status
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    APIs.getSelfInfo();

    //for updating user active status according to lifecycle events
    //resume -- active or online
    //pause  -- inactive or offline
    SystemChannels.lifecycle.setMessageHandler((message) {
      log('Message: $message');

      if (APIs.auth.currentUser != null) {
        if (message.toString().contains('resume')) {
          APIs.updateActiveStatus(true);
        }
        if (message.toString().contains('pause')) {
          APIs.updateActiveStatus(false);
        }
      }

      return Future.value(message);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      //for hiding keyboard when a tap is detected on screen
      onTap: FocusScope.of(context).unfocus,
      child: Container(
        // Apply gradient background
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFFFC1CC), // Light pink
              Color.fromARGB(255, 238, 93, 153), // Medium pink
              Color.fromARGB(255, 142, 13, 152), // Dark purple
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: PopScope(
          // if search is on & back button is pressed then close search
          // or else simple close current screen on back button click
          canPop: false,
          onPopInvoked: (_) {
            if (_isSearching) {
              setState(() => _isSearching = !_isSearching);
              return;
            }

            // some delay before pop
            Future.delayed(
                const Duration(milliseconds: 300), SystemNavigator.pop);
          },

          child: Scaffold(
            // Make scaffold background transparent to show gradient
            backgroundColor: Colors.transparent,

            //app bar
            appBar: AppBar(
              //view profile
              leading: IconButton(
                tooltip: 'View Profile',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => ProfileScreen(user: APIs.me)),
                  );
                },
                icon: const ProfileImage(size: 32),
              ),

              //title
              title: _isSearching
                  ? TextField(
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Enter email or name to search',
                      ),
                      autofocus: true,
                      style: const TextStyle(fontSize: 17, letterSpacing: 0.5),
                      onChanged: (val) {
                        // search logic
                        _searchList.clear();

                        val = val.toLowerCase();
                        for (var i in _list) {
                          if (i.name.toLowerCase().contains(val) ||
                              i.email.toLowerCase().contains(val)) {
                            _searchList.add(i);
                          }
                        }
                        setState(() => _searchList);
                      },
                    )
                  : const Text('Chat Screen'),
              actions: [
                IconButton(
                  tooltip: 'Search',
                  onPressed: () => setState(() => _isSearching = !_isSearching),
                  icon: Icon(_isSearching
                      ? CupertinoIcons.clear_circled_solid
                      : CupertinoIcons.search),
                ),
              ],
            ),

            //floating button to add new user
            floatingActionButton: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: FloatingActionButton(
                backgroundColor: Colors.white,
                onPressed: () {
                  _addChatUserDialog();
                },
                child: Image.asset(
                  'assets/images/plus.png', // Path to your PNG image
                  width: 30,
                  height: 30,
                ),
              ),
            ),

            //body
            body: StreamBuilder(
              stream: APIs.getMyUsersId(),
              builder: (context, snapshot) {
                switch (snapshot.connectionState) {
                  case ConnectionState.waiting:
                  case ConnectionState.none:
                    return const Center(child: CircularProgressIndicator());

                  case ConnectionState.active:
                  case ConnectionState.done:
                    return StreamBuilder(
                      stream: APIs.getAllUsers(
                          snapshot.data?.docs.map((e) => e.id).toList() ?? []),
                      builder: (context, snapshot) {
                        switch (snapshot.connectionState) {
                          case ConnectionState.waiting:
                          case ConnectionState.none:
                          case ConnectionState.active:
                          case ConnectionState.done:
                            final data = snapshot.data?.docs;
                            _list = data
                                    ?.map((e) => ChatUser.fromJson(e.data()))
                                    .toList() ??
                                [];

                            if (_list.isNotEmpty) {
                              return ListView.builder(
                                itemCount: _isSearching
                                    ? _searchList.length
                                    : _list.length,
                                padding: EdgeInsets.only(top: mq.height * .01),
                                physics: const BouncingScrollPhysics(),
                                itemBuilder: (context, index) {
                                  return ChatUserCard(
                                    user: _isSearching
                                        ? _searchList[index]
                                        : _list[index],
                                  );
                                },
                              );
                            } else {
                              return const Center(
                                child: Text(
                                  'Chats Not Found',
                                  style: TextStyle(fontSize: 20),
                                ),
                              );
                            }
                        }
                      },
                    );
                }
              },
            ),
          ),
        ),
      ),
    );
  }

  // for adding new chat user
  void _addChatUserDialog() {
    String email = '';

    showDialog(
        context: context,
        builder: (_) => AlertDialog(
              contentPadding: const EdgeInsets.only(
                  left: 24, right: 24, top: 20, bottom: 10),

              shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(15))),

              //title
              title: const Row(
                children: [
                  Icon(
                    Icons.person_add,
                    color: Color.fromARGB(255, 192, 21, 163),
                    size: 28,
                  ),
                  Text('  Add people')
                ],
              ),

              //content
              content: TextFormField(
                maxLines: null,
                onChanged: (value) => email = value,
                decoration: const InputDecoration(
                    hintText: 'Enter Email Id',
                    prefixIcon: Icon(
                      Icons.email,
                      color: Color.fromARGB(255, 192, 21, 163),
                    ),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(15)))),
              ),

              //actions
              actions: [
                //cancel button
                MaterialButton(
                    onPressed: () {
                      //hide alert dialog
                      Navigator.pop(context);
                    },
                    child: const Text('Cancel',
                        style: TextStyle(
                            color: Color.fromARGB(255, 192, 21, 163),
                            fontSize: 16))),

                //add button
                MaterialButton(
                    onPressed: () async {
                      //hide alert dialog
                      Navigator.pop(context);
                      if (email.trim().isNotEmpty) {
                        await APIs.addChatUser(email).then((value) {
                          if (!value) {
                            Dialogs.showSnackbar(
                                context, 'User does not Exists!');
                          }
                        });
                      }
                    },
                    child: const Text(
                      'Start Chat',
                      style: TextStyle(
                        color: Color.fromARGB(255, 192, 21, 163),
                        fontSize: 16,
                      ),
                    ))
              ],
            ));
  }
}
