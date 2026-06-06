import 'dart:convert';

import 'package:anabulcare/services/post_service.dart';
import 'package:anabulcare/models/post.dart';
import 'package:anabulcare/screens/detail_screen.dart';
import 'package:anabulcare/screens/add_post_screen.dart';
import 'package:flutter/material.dart';

class PostListItem extends StatelessWidget {
  final Post post;
  final bool isOwner;

  const PostListItem({super.key, required this.post, required this.isOwner});

  Future<void> _deletePost(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Post'),
        content: const Text('Are you sure you want to delete this post?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await PostService.deletePost(post);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        onTap: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => DetailScreen(post: post)));
        },
        leading: post.image != null && post.image!.isNotEmpty
            ? ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.memory(
                  base64Decode(post.image!),
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.broken_image, size: 56),
                ),
              )
            : const Icon(Icons.article, size: 56),
        title: Text(
          post.category ?? 'No Category',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              post.description ?? '',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              post.userFullName ?? '',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        isThreeLine: true,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isOwner) ...[
              IconButton(
                onPressed: () async {
                  // Navigate to AddPostScreen in admin mode passing the post for editing
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          AddPostScreen(isAdmin: true, coffeeShop: post),
                    ),
                  );
                  // If edited, optional: you can refresh via StreamBuilder in parent
                },
                icon: const Icon(Icons.edit, color: Colors.blue),
                tooltip: 'Edit',
              ),
              IconButton(
                onPressed: () => _deletePost(context),
                icon: const Icon(Icons.delete, color: Colors.red),
                tooltip: 'Delete',
              ),
            ],
          ],
        ),
      ),
    );
  }
}
