import 'package:flutter/material.dart';

/// Represents a concept category in the FAANG roadmap mind map
class ConceptCategory {
  final String id;
  final String name;
  final String description;
  final Color color;
  final IconData icon;
  final List<String> keywords; // Used to match notes
  final List<ConceptCategory> children;
  final Offset? position; // For custom positioning

  const ConceptCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.color,
    required this.icon,
    this.keywords = const [],
    this.children = const [],
    this.position,
  });
}

/// FAANG Interview Roadmap categories
class FaangRoadmap {
  static const Color dsaColor = Color(0xFF6366F1); // Indigo
  static const Color systemDesignColor = Color(0xFFEC4899); // Pink
  static const Color behavioralColor = Color(0xFF10B981); // Emerald
  static const Color languageColor = Color(0xFFF59E0B); // Amber
  static const Color practiceColor = Color(0xFF3B82F6); // Blue
  static const Color mathColor = Color(0xFF8B5CF6); // Purple
  static const Color osColor = Color(0xFFEF4444); // Red
  static const Color networkColor = Color(0xFF14B8A6); // Teal

  static final ConceptCategory root = ConceptCategory(
    id: 'faang',
    name: 'FAANG Interview',
    description: 'Complete roadmap for FAANG interviews',
    color: const Color(0xFF1F2937),
    icon: Icons.rocket_launch,
    children: [
      dataStructures,
      algorithms,
      systemDesign,
      behavioral,
      programmingLanguages,
      mathAndLogic,
      operatingSystems,
      networking,
    ],
  );

  static final ConceptCategory dataStructures = ConceptCategory(
    id: 'data-structures',
    name: 'Data Structures',
    description: 'Essential data structures for coding interviews',
    color: dsaColor,
    icon: Icons.account_tree,
    keywords: ['array', 'linked list', 'stack', 'queue', 'tree', 'graph', 'hash', 'heap', 'trie'],
    children: [
      ConceptCategory(
        id: 'arrays',
        name: 'Arrays & Strings',
        description: 'Array manipulation and string algorithms',
        color: dsaColor.withOpacity(0.85),
        icon: Icons.view_array,
        keywords: ['array', 'string', 'two pointer', 'sliding window'],
      ),
      ConceptCategory(
        id: 'linked-lists',
        name: 'Linked Lists',
        description: 'Singly, doubly, and circular linked lists',
        color: dsaColor.withOpacity(0.85),
        icon: Icons.link,
        keywords: ['linked list', 'node', 'pointer'],
      ),
      ConceptCategory(
        id: 'stacks-queues',
        name: 'Stacks & Queues',
        description: 'LIFO and FIFO data structures',
        color: dsaColor.withOpacity(0.85),
        icon: Icons.layers,
        keywords: ['stack', 'queue', 'deque', 'monotonic'],
      ),
      ConceptCategory(
        id: 'trees',
        name: 'Trees',
        description: 'Binary trees, BST, and tree traversals',
        color: dsaColor.withOpacity(0.85),
        icon: Icons.park,
        keywords: ['tree', 'binary', 'bst', 'traversal', 'dfs', 'bfs'],
      ),
      ConceptCategory(
        id: 'graphs',
        name: 'Graphs',
        description: 'Graph representations and algorithms',
        color: dsaColor.withOpacity(0.85),
        icon: Icons.hub,
        keywords: ['graph', 'adjacency', 'vertex', 'edge', 'directed', 'undirected'],
      ),
      ConceptCategory(
        id: 'hash-tables',
        name: 'Hash Tables',
        description: 'Hashing and collision handling',
        color: dsaColor.withOpacity(0.85),
        icon: Icons.tag,
        keywords: ['hash', 'map', 'set', 'dictionary'],
      ),
      ConceptCategory(
        id: 'heaps',
        name: 'Heaps & Priority Queues',
        description: 'Min/max heaps and priority queues',
        color: dsaColor.withOpacity(0.85),
        icon: Icons.filter_list,
        keywords: ['heap', 'priority queue', 'min heap', 'max heap'],
      ),
      ConceptCategory(
        id: 'tries',
        name: 'Tries',
        description: 'Prefix trees for string operations',
        color: dsaColor.withOpacity(0.85),
        icon: Icons.text_fields,
        keywords: ['trie', 'prefix', 'autocomplete'],
      ),
    ],
  );

  static final ConceptCategory algorithms = ConceptCategory(
    id: 'algorithms',
    name: 'Algorithms',
    description: 'Core algorithmic techniques',
    color: const Color(0xFF0EA5E9), // Sky blue
    icon: Icons.functions,
    keywords: ['algorithm', 'complexity', 'big o'],
    children: [
      ConceptCategory(
        id: 'sorting',
        name: 'Sorting',
        description: 'Various sorting algorithms',
        color: const Color(0xFF0EA5E9).withOpacity(0.85),
        icon: Icons.sort,
        keywords: ['sort', 'merge sort', 'quick sort', 'heap sort', 'bubble sort'],
      ),
      ConceptCategory(
        id: 'searching',
        name: 'Searching',
        description: 'Binary search and variations',
        color: const Color(0xFF0EA5E9).withOpacity(0.85),
        icon: Icons.search,
        keywords: ['search', 'binary search', 'linear search'],
      ),
      ConceptCategory(
        id: 'recursion',
        name: 'Recursion & Backtracking',
        description: 'Recursive problem solving',
        color: const Color(0xFF0EA5E9).withOpacity(0.85),
        icon: Icons.replay,
        keywords: ['recursion', 'backtracking', 'recursive'],
      ),
      ConceptCategory(
        id: 'dynamic-programming',
        name: 'Dynamic Programming',
        description: 'DP patterns and memoization',
        color: const Color(0xFF0EA5E9).withOpacity(0.85),
        icon: Icons.table_chart,
        keywords: ['dynamic programming', 'dp', 'memoization', 'tabulation'],
      ),
      ConceptCategory(
        id: 'greedy',
        name: 'Greedy Algorithms',
        description: 'Greedy approach and optimization',
        color: const Color(0xFF0EA5E9).withOpacity(0.85),
        icon: Icons.trending_up,
        keywords: ['greedy', 'optimal', 'local optimum'],
      ),
      ConceptCategory(
        id: 'graph-algorithms',
        name: 'Graph Algorithms',
        description: 'DFS, BFS, shortest path, etc.',
        color: const Color(0xFF0EA5E9).withOpacity(0.85),
        icon: Icons.route,
        keywords: ['dfs', 'bfs', 'dijkstra', 'bellman', 'shortest path', 'topological'],
      ),
      ConceptCategory(
        id: 'divide-conquer',
        name: 'Divide & Conquer',
        description: 'Breaking problems into subproblems',
        color: const Color(0xFF0EA5E9).withOpacity(0.85),
        icon: Icons.call_split,
        keywords: ['divide', 'conquer', 'merge'],
      ),
    ],
  );

  static final ConceptCategory systemDesign = ConceptCategory(
    id: 'system-design',
    name: 'System Design',
    description: 'Large-scale system design concepts',
    color: systemDesignColor,
    icon: Icons.architecture,
    keywords: ['system design', 'architecture', 'scalability', 'distributed'],
    children: [
      ConceptCategory(
        id: 'fundamentals',
        name: 'Fundamentals',
        description: 'Core system design concepts',
        color: systemDesignColor.withOpacity(0.85),
        icon: Icons.foundation,
        keywords: ['cap theorem', 'consistency', 'availability', 'partition'],
      ),
      ConceptCategory(
        id: 'databases',
        name: 'Databases',
        description: 'SQL, NoSQL, and data storage',
        color: systemDesignColor.withOpacity(0.85),
        icon: Icons.storage,
        keywords: ['database', 'sql', 'nosql', 'sharding', 'replication'],
      ),
      ConceptCategory(
        id: 'caching',
        name: 'Caching',
        description: 'Caching strategies and systems',
        color: systemDesignColor.withOpacity(0.85),
        icon: Icons.speed,
        keywords: ['cache', 'redis', 'memcached', 'cdn'],
      ),
      ConceptCategory(
        id: 'load-balancing',
        name: 'Load Balancing',
        description: 'Traffic distribution strategies',
        color: systemDesignColor.withOpacity(0.85),
        icon: Icons.balance,
        keywords: ['load balancer', 'round robin', 'nginx'],
      ),
      ConceptCategory(
        id: 'message-queues',
        name: 'Message Queues',
        description: 'Async communication patterns',
        color: systemDesignColor.withOpacity(0.85),
        icon: Icons.queue,
        keywords: ['queue', 'kafka', 'rabbitmq', 'pub sub'],
      ),
      ConceptCategory(
        id: 'microservices',
        name: 'Microservices',
        description: 'Service-oriented architecture',
        color: systemDesignColor.withOpacity(0.85),
        icon: Icons.apps,
        keywords: ['microservice', 'api gateway', 'service mesh'],
      ),
    ],
  );

  static final ConceptCategory behavioral = ConceptCategory(
    id: 'behavioral',
    name: 'Behavioral',
    description: 'Soft skills and behavioral interviews',
    color: behavioralColor,
    icon: Icons.psychology,
    keywords: ['behavioral', 'leadership', 'teamwork', 'star method'],
    children: [
      ConceptCategory(
        id: 'star-method',
        name: 'STAR Method',
        description: 'Situation, Task, Action, Result',
        color: behavioralColor.withOpacity(0.85),
        icon: Icons.star,
        keywords: ['star', 'situation', 'task', 'action', 'result'],
      ),
      ConceptCategory(
        id: 'leadership',
        name: 'Leadership',
        description: 'Leadership principles and examples',
        color: behavioralColor.withOpacity(0.85),
        icon: Icons.person,
        keywords: ['leadership', 'lead', 'mentor', 'initiative'],
      ),
      ConceptCategory(
        id: 'conflict',
        name: 'Conflict Resolution',
        description: 'Handling disagreements',
        color: behavioralColor.withOpacity(0.85),
        icon: Icons.handshake,
        keywords: ['conflict', 'disagreement', 'resolution'],
      ),
      ConceptCategory(
        id: 'failure',
        name: 'Failure & Growth',
        description: 'Learning from mistakes',
        color: behavioralColor.withOpacity(0.85),
        icon: Icons.trending_down,
        keywords: ['failure', 'mistake', 'learn', 'growth'],
      ),
    ],
  );

  static final ConceptCategory programmingLanguages = ConceptCategory(
    id: 'languages',
    name: 'Programming Languages',
    description: 'Language-specific concepts',
    color: languageColor,
    icon: Icons.code,
    keywords: ['java', 'python', 'javascript', 'c++', 'go', 'rust'],
    children: [
      ConceptCategory(
        id: 'java',
        name: 'Java',
        description: 'Java fundamentals and JVM',
        color: languageColor.withOpacity(0.85),
        icon: Icons.coffee,
        keywords: ['java', 'jvm', 'spring', 'collections'],
      ),
      ConceptCategory(
        id: 'python',
        name: 'Python',
        description: 'Python for interviews',
        color: languageColor.withOpacity(0.85),
        icon: Icons.code,
        keywords: ['python', 'pythonic', 'list comprehension'],
      ),
      ConceptCategory(
        id: 'javascript',
        name: 'JavaScript',
        description: 'JS/TS concepts',
        color: languageColor.withOpacity(0.85),
        icon: Icons.javascript,
        keywords: ['javascript', 'typescript', 'node', 'async'],
      ),
    ],
  );

  static final ConceptCategory mathAndLogic = ConceptCategory(
    id: 'math',
    name: 'Math & Logic',
    description: 'Mathematical foundations',
    color: mathColor,
    icon: Icons.calculate,
    keywords: ['math', 'logic', 'probability', 'statistics'],
    children: [
      ConceptCategory(
        id: 'bit-manipulation',
        name: 'Bit Manipulation',
        description: 'Binary operations and tricks',
        color: mathColor.withOpacity(0.85),
        icon: Icons.memory,
        keywords: ['bit', 'binary', 'xor', 'bitwise'],
      ),
      ConceptCategory(
        id: 'number-theory',
        name: 'Number Theory',
        description: 'GCD, primes, modular arithmetic',
        color: mathColor.withOpacity(0.85),
        icon: Icons.numbers,
        keywords: ['prime', 'gcd', 'lcm', 'modular'],
      ),
      ConceptCategory(
        id: 'probability',
        name: 'Probability',
        description: 'Probability and combinatorics',
        color: mathColor.withOpacity(0.85),
        icon: Icons.casino,
        keywords: ['probability', 'combinatorics', 'permutation', 'combination'],
      ),
    ],
  );

  static final ConceptCategory operatingSystems = ConceptCategory(
    id: 'os',
    name: 'Operating Systems',
    description: 'OS fundamentals',
    color: osColor,
    icon: Icons.computer,
    keywords: ['operating system', 'os', 'process', 'thread', 'memory'],
    children: [
      ConceptCategory(
        id: 'processes',
        name: 'Processes & Threads',
        description: 'Concurrency and parallelism',
        color: osColor.withOpacity(0.85),
        icon: Icons.call_split,
        keywords: ['process', 'thread', 'concurrency', 'parallelism'],
      ),
      ConceptCategory(
        id: 'memory',
        name: 'Memory Management',
        description: 'Virtual memory, paging',
        color: osColor.withOpacity(0.85),
        icon: Icons.memory,
        keywords: ['memory', 'virtual memory', 'paging', 'segmentation'],
      ),
      ConceptCategory(
        id: 'synchronization',
        name: 'Synchronization',
        description: 'Locks, semaphores, deadlocks',
        color: osColor.withOpacity(0.85),
        icon: Icons.sync,
        keywords: ['lock', 'mutex', 'semaphore', 'deadlock'],
      ),
    ],
  );

  static final ConceptCategory networking = ConceptCategory(
    id: 'networking',
    name: 'Networking',
    description: 'Network fundamentals',
    color: networkColor,
    icon: Icons.lan,
    keywords: ['network', 'tcp', 'http', 'dns', 'ip'],
    children: [
      ConceptCategory(
        id: 'protocols',
        name: 'Protocols',
        description: 'TCP/IP, HTTP, WebSocket',
        color: networkColor.withOpacity(0.85),
        icon: Icons.swap_horiz,
        keywords: ['tcp', 'udp', 'http', 'https', 'websocket'],
      ),
      ConceptCategory(
        id: 'dns',
        name: 'DNS & CDN',
        description: 'Domain resolution and content delivery',
        color: networkColor.withOpacity(0.85),
        icon: Icons.dns,
        keywords: ['dns', 'cdn', 'domain'],
      ),
      ConceptCategory(
        id: 'security',
        name: 'Security',
        description: 'TLS, OAuth, encryption',
        color: networkColor.withOpacity(0.85),
        icon: Icons.security,
        keywords: ['security', 'ssl', 'tls', 'oauth', 'encryption'],
      ),
    ],
  );

  /// Get all categories as a flat list
  static List<ConceptCategory> getAllCategories() {
    final List<ConceptCategory> result = [];
    void traverse(ConceptCategory category) {
      result.add(category);
      for (final child in category.children) {
        traverse(child);
      }
    }
    traverse(root);
    return result;
  }

  /// Find category by ID
  static ConceptCategory? findById(String id) {
    ConceptCategory? find(ConceptCategory category) {
      if (category.id == id) return category;
      for (final child in category.children) {
        final found = find(child);
        if (found != null) return found;
      }
      return null;
    }
    return find(root);
  }
}
