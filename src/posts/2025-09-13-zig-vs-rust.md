---
title: 'Why Zig is better than Rust (And why it won''t stop)'
keywords: [zig, vs, rust, c, programming, language design, comparison, which better, compilation times, comptime, performance, rust alternatives]
date: 2025-09-13
meta-date: 2025-09-13
abstract: |
    Hi! Over the years of studying computer science, I have tried many languages, such as Java, Go, Rust. But I always come back to Zig. Rust has always been almost perfect for me, but that time I realized how unproductive it was to use. I will prove to you that Zig has a great future.
---

Hi! Over the years of studying computer science, I have tried many languages, such as Java, Go, Rust. But I always come back to Zig. Rust has always been almost perfect for me, but that time I realized how unproductive it was to use. I will prove to you that Zig has a great future.

# There are many reasons...

First of all, **I don't want to discrediting Rust maintainers or language itself**. Tokio is one of the best async runtimes that currently exists. If you need to make a more battle-tested application, use Rust. Rust is awesome and production ready language.

Fighting borrow checker is a very difficult task and incredibly rewarding, but you get one of the best guarantees of memory safety after that. But I find Zig more enjoyable and more productive for me and here's why:

### 1. Minimalism

I like that Zig is minimalistic, but it has the same capabilities as Rust. Rust has unnecessary complex macros and concepts (Macros are still bad in any form) and may encounter the same problem as in C++, which it is trying to fix. Rust syntax is already huge. But what did Zig do? It has fixed C so that it can be used in typical modern applications. This simple fix made the language not only faster and lighter than Rust, but also provided almost the same level of safety as Rust.

Talking about "packages". Rust is very likely to encounter a Node.js problem. It will bloat to an incredible size with rapid increase of Cargo crates, which will be more hassle to maintain, especially with macros, and even a small project will weight more than 10MB or 150MB in some cases (This can be avoided, but more effort is needed, don't get me wrong!), because every crate is linked statically by default. On the other hand, Zig often produces smaller binaries because its compiler performs extensive compile‑time evaluation and the language design, like lazy analysis, helps, and Zig adapts better to the C ABI because both C and Zig​are very similar, whereas Rust does allow dynamic linking only through `cdylib`/`dylib` crate types and against C libraries.

You think that unlike Rust, Zig doesn’t have any kind of interfaces—like Rust’s traits? You’re wrong; you probably missed `@fieldParentPtr`{.zig}! Zig lets you retrieve the containing pointer to a struct from a field, which is the cornerstone of building interfaces without any hidden magic. Despite the simple language, you can do such modern things. 

To be fair, in Zig, safety checks are performed at runtime rather than compile time, but a lot of work has been done to provide more and more compile-time checks, unlike in Rust, which performs more compile-time and runtime checks by default. Compile-time checks are preferable.

### 2. More straightforward metaprogramming

With Zig you have more approachable metaprogramming. It does not have unnecessary complex macros or insane attributes. Rust tries to be absolute flexible in this case, but in 95% of cases it's not necessary.

Look at this code:

```zig
switch (slice) {
  inline .FooSlice, .BarSlice => |baz| {
      var string: []u8 = undefined;

      const data = try reader.readAlloc(alloc, length);
      defer alloc.free(data);
      string = try alloc.alloc(u8, length);
      errdefer alloc.free(string);
      @memcpy(string, data);

      return @unionInit(Node, @tagName(baz), string);
    }
  }
  // ...
}
```

Here we take the value from the reader. Then, when we are ready, we return the union. The difference is that we can very conveniently avoid repeating the code using `inline`{.zig} and `@unionInit`{.zig}. Very cool, isn't it?

To be fair, there's `syn` and `quote` Rust crates, but Zig's metaprogramming is still better, since it lets you write compile‑time code directly in the language without pulling in an external parsing library, offers full type safety and IDE support. Also, `comptime`{.zig} could be slow, because it uses garbage collector and slower that CPython. [It will be addressed](https://github.com/ziglang/zig/issues/4055#issuecomment-1646701374), because it's requires fundamental changes of the compiler.

### 3. It's explicit

One of the most important aspect of the low level programming is allocations on heap. In Zig it's not hidden. You have more vision of how function allocates the memory. If it asks for allocator that's obvious that he needs additional memory or need to free it:

```zig
pub fn loadConfig(allocator: std.mem.Allocator) !Config {  
    const data = try allocator.alloc(u8, 1024);  
    defer allocator.free(data);  
    // ...  
}  
```

In Rust, you can override operators. What happens if you add two objects? It can do an I/O operation, overflow the stack or heap, or call UB. You decide!

The source code of the standard library is readable even without comments, because that's how the language is designed. The language forces you to handle any error union or does not allow you to define a function that could potentially cause an exception. The syntax is also very expressive and simple. But Rust is about clever code. But readable code is better than clever code, because you need to understand what the program does, otherwise it is difficult to understand what is happening (C++ does the same btw). In addition, many language developers do not consider the possibility of hidden flow control, which makes it less secure and readable. You can write Zig code with hidden flow control, but it is more explicit than in other languages.

One piece of advice for you: It is more efficient to use the `Unmanaged` variants from the standard library, because they are easier to manage, they take up less memory and to a greater extent ensure the "no hidden allocations". And [in version 0.15.1 ArrayList is getting deprecated](https://ziglang.org/download/0.15.1/release-notes.html#ArrayList-make-unmanaged-the-default).

### 4. Safety without sacrificing usability

As much as I praise Rust's safety, its safety leaves many questions. Rust’s guarantees are largely enforced by its borrow‑checker and ownership system, which prevent data races, use‑after‑free bugs, and many classes of memory errors at compile time. However, these guarantees come with a steep learning curve, and the compiler’s diagnostics can sometimes be cryptic, especially when dealing with complex lifetimes, generic code, or unsafe blocks. And even after that, it is [not a guarantee of code safety](https://github.com/Speykious/cve-rs), which sucks!
Zig doesn't have such a problem, since Zig has manual memory management and more explicit code. Zig’s design deliberately avoids hidden abstractions: memory is allocated and freed explicitly, and the language provides clear, low‑level control over pointers and lifetimes. This transparency makes it easier to reason about what the program is doing at any given moment.

It may seem funny that in a language with manual memory management, safety is almost at the same level, but some features let write more safe code, for example, `DebugAllocator` detect memory leaks with ease:

```zig
var debug_allocator = std.heap.DebugAllocator(.{}){};
defer std.debug.assert(gpa_alloc.deinit() == .ok);
const allocator = debug_allocator.allocator();

const arr = allocator.alloc(u8, 8);
// OOPS, forgot
// defer alloc.free(arr);
```

`assert` will cause illegal behavior that will indicate a problem.

To be honest, I have not studied the interaction with C FFI in Rust, but many people complain about it. You can research this yourself, as I've never worked with `unsafe` code in Rust. There are articles that compare both languages and check if they talking about C FFI. I've never had to link to the C library. But as far as I know, Zig has direct support for C FFI with `@cImport`, special types and `callconv(.C)`.

### 5. Short compilation time

The main problem of developers is compilation time. Rust is very bad in this regard. Zig developers are trying their best to minimize compilation time. They even want to [remove the LLVM backend for the compiler](https://github.com/ziglang/zig/issues/16270) to reduce compilation time and reduce bugs that they didn't caused. Zig makes everything faster and more reliable.
The divorce papers has already been signed for the [x86_64 architecture](https://ziglang.org/download/0.15.1/release-notes.html#x86-Backend) and the next one is [aarch64](https://ziglang.org/download/0.15.1/release-notes.html#aarch64-Backend).

### 6. Zig community is not superior

The Rust community pisses me off that they're trying to rewrite the entire universe in Rust. Not every project needs to be "memory safe". Why the hell is [tmux will be based on Rust now](https://lwn.net/Articles/1028583/)? Why is the community trying to rewrite tmux? Why? And add `-rs` to everything they see. The Zig community is more friendly and fun, and has created many useful libraries. *This is already a rant, but I can't speak for everyone, so take it a bit with a grain of salt.*

# Not everything is "Sunshine and rainbows"

You think that Zig is better? Actually not quite, but it's matter of time. Here's the issues that I found:

### 1. Asynchrony programming is `// TODO`

Unfortunately, asynchronous programming is not ready and not integrated with the standard library and syntax, but it will be available as [I/O interface](https://ziglang.org/download/0.15.1/release-notes.html#IO-as-an-Interface) in future 0.16.0 release. But this can be avoided by using non-blocking I/O and multithreading, or a custom event-loop like [libxev](https://github.com/mitchellh/libxev).

### 2. Too young

You won't see any crazy or super useful libraries for Zig right now, because the ecosystem isn't very mature yet. Non code related applications (like Discord) do not have syntax highlighting for Zig, and I had to grab the [XML syntax data from the KDE repository](https://invent.kde.org/frameworks/syntax-highlighting/-/blob/master/data/syntax/zig.xml) specifically for this post. Some may still be telling old information even now. Also, the standard library isn't fully documented, but there are plenty of blogs about using standard library. Breakages may happen over time, so be prepared. See [Roadmap](https://ziglang.org/download/0.15.1/release-notes.html#Roadmap).

# Conclusion

Zig is the most enjoyable experience of my life. It is a fun and reliable language.
Still, those very imperfections are part of what makes Zig exciting. They signal a language still in its formative years, open to community input and rapid improvement. If you value a tool that prioritizes clarity, speed, and control, and you’re comfortable contributing to a budding ecosystem, Zig offers a compelling alternative that’s unlikely to fade anytime soon.
Someone said it already, but "Zig is better than unsafe Rust right now" and I absolutely agree with that. So whether you’re just starting out, looking to experiment with a new systems language, or seeking a fresh perspective on low‑level programming, give Zig a try.
