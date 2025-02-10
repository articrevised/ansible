---
- name: Update system and clean up
  hosts: all
  become: yes
  tasks:
    - name: Update package list
      apt:
        update_cache: yes

    - name: Upgrade installed packages
      apt:
        upgrade: dist
        cache_valid_time: 3600

    - name: Remove unnecessary packages and dependencies
      apt:
        autoremove: yes

    - name: Clean up package cache
      apt:
        autoclean: yes

    - name: Clear temporary files
      file:
        path: /tmp
        state: absent

    - name: Recreate /tmp directory
      file:
        path: /tmp
        state: directory
        mode: '1777'

    - name: Clear system cache
      command: sync
      changed_when: false

    - name: Drop system caches
      command: sysctl -w vm.drop_caches=3
      changed_when: false

    - name: Clear user cache
      file:
        path: "{{ ansible_user_dir }}/.cache"
        state: absent

    - name: Recreate user cache directory
      file:
        path: "{{ ansible_user_dir }}/.cache"
        state: directory
        mode: '0755'

    - name: Print completion message
      debug:
        msg: "System update and cleanup complete!"
