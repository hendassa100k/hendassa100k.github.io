---
date: '{{ (.Date | time.AsTime).Format "2006-01-02T00:00:00-07:00" }}'
draft: true
title: '{{ replace .File.ContentBaseName "-" " " | title }}'
---
