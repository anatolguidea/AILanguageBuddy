<!-- Lesson Light Mode -->
<!DOCTYPE html>

<html lang="en"><head>
<meta charset="utf-8"/>
<meta content="width=device-width, initial-scale=1.0" name="viewport"/>
<title>Lesson Light Mode</title>
<script src="https://cdn.tailwindcss.com?plugins=forms,container-queries"></script>
<link href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:wght,FILL@100..700,0..1&amp;display=swap" rel="stylesheet"/>
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&amp;display=swap" rel="stylesheet"/>
<link href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:wght,FILL@100..700,0..1&amp;display=swap" rel="stylesheet"/>
<script id="tailwind-config">
        tailwind.config = {
            darkMode: "class",
            theme: {
                extend: {
                    colors: {
                        "primary": "#ff6a00",
                        "background-light": "#f8f7f5",
                        "background-dark": "#23170f",
                        "text-dark": "#181410",
                    },
                    fontFamily: {
                        "display": ["Inter", "sans-serif"]
                    },
                    borderRadius: {
                        "DEFAULT": "0.25rem",
                        "lg": "0.5rem",
                        "xl": "0.75rem",
                        "2xl": "1rem",
                        "full": "9999px"
                    },
                },
            },
        }
    </script>
<style>
        body {
            font-family: 'Inter', sans-serif;
            -webkit-font-smoothing: antialiased;
        }
    </style>
<style>
    body {
      min-height: max(884px, 100dvh);
    }
  </style>
  </head>
<body class="bg-background-light dark:bg-background-dark min-h-screen flex justify-center text-text-dark dark:text-white">
<div class="w-full max-w-md bg-white dark:bg-[#1f1610] h-full min-h-screen flex flex-col relative shadow-xl overflow-hidden">
<!-- Header with Close Icon and Progress Bar -->
<div class="px-5 pt-6 pb-2 flex items-center gap-4">
<button class="text-[#9e9a96] hover:text-text-dark dark:hover:text-white transition-colors">
<span class="material-symbols-outlined text-3xl">close</span>
</button>
<div class="flex-1 h-3 bg-[#e7dfda] dark:bg-[#3a2e26] rounded-full overflow-hidden">
<div class="h-full bg-primary rounded-full" style="width: 40%;"></div>
</div>
</div>
<!-- Main Content Area -->
<div class="flex-1 px-5 flex flex-col justify-center">
<!-- Question -->
<div class="mb-8">
<h1 class="text-3xl font-bold tracking-tight text-text-dark dark:text-white leading-tight">
                    How do you feel today?
                </h1>
<p class="text-[#9e9a96] mt-2 text-base font-medium">Select the option that fits best.</p>
</div>
<!-- Options Grid -->
<div class="flex flex-col gap-4">
<!-- Card 1: Happy (Selected) -->
<button class="group relative flex items-center p-5 gap-5 rounded-2xl border-2 border-primary bg-primary/5 dark:bg-primary/10 transition-all active:scale-[0.98]">
<div class="flex items-center justify-center w-16 h-16 text-[48px] bg-white dark:bg-[#2c221c] rounded-xl shadow-sm leading-none">
                        😊
                    </div>
<div class="flex flex-col items-start flex-1">
<span class="text-xl font-bold text-text-dark dark:text-white">Happy</span>
</div>
<div class="w-6 h-6 rounded-full bg-primary flex items-center justify-center">
<span class="material-symbols-outlined text-white text-lg font-bold">check</span>
</div>
</button>
<!-- Card 2: Sad (Unselected) -->
<button class="group relative flex items-center p-5 gap-5 rounded-2xl border-2 border-transparent bg-white dark:bg-[#2c221c] shadow-[0_2px_8px_rgba(0,0,0,0.04)] hover:bg-[#fcfbf9] dark:hover:bg-[#362b24] transition-all active:scale-[0.98]">
<div class="flex items-center justify-center w-16 h-16 text-[48px] bg-[#f8f7f5] dark:bg-[#3a2e26] rounded-xl leading-none">
                        😢
                    </div>
<div class="flex flex-col items-start flex-1">
<span class="text-xl font-bold text-text-dark dark:text-white">Sad</span>
</div>
<!-- Empty circle for unselected state visual balance -->
<div class="w-6 h-6 rounded-full border-2 border-[#e7dfda] dark:border-[#52453d]"></div>
</button>
<!-- Card 3: Tired (Unselected) -->
<button class="group relative flex items-center p-5 gap-5 rounded-2xl border-2 border-transparent bg-white dark:bg-[#2c221c] shadow-[0_2px_8px_rgba(0,0,0,0.04)] hover:bg-[#fcfbf9] dark:hover:bg-[#362b24] transition-all active:scale-[0.98]">
<div class="flex items-center justify-center w-16 h-16 text-[48px] bg-[#f8f7f5] dark:bg-[#3a2e26] rounded-xl leading-none">
                        😴
                    </div>
<div class="flex flex-col items-start flex-1">
<span class="text-xl font-bold text-text-dark dark:text-white">Tired</span>
</div>
<div class="w-6 h-6 rounded-full border-2 border-[#e7dfda] dark:border-[#52453d]"></div>
</button>
</div>
</div>
<!-- Footer Action -->
<div class="p-5 pb-8 bg-white dark:bg-[#1f1610] border-t border-[#f0ebe8] dark:border-[#2c221c]">
<button class="w-full h-14 rounded-xl bg-primary hover:bg-[#e65f00] text-white text-lg font-bold tracking-wide shadow-lg shadow-primary/30 transition-all flex items-center justify-center uppercase">
                Continue
            </button>
</div>
</div>
</body></html>

<!-- Profile Dark Mode -->
<!DOCTYPE html>

<html lang="en"><head>
<meta charset="utf-8"/>
<meta content="width=device-width, initial-scale=1.0" name="viewport"/>
<title>Profile Dark Mode</title>
<script src="https://cdn.tailwindcss.com?plugins=forms,container-queries"></script>
<link href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:wght,FILL@100..700,0..1&amp;display=swap" rel="stylesheet"/>
<link href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:wght,FILL@100..700,0..1&amp;display=swap" rel="stylesheet"/>
<style>
        @import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap');
    </style>
<script id="tailwind-config">
        tailwind.config = {
            darkMode: "class",
            theme: {
                extend: {
                    colors: {
                        "primary": "#ff6a00",
                        "background-light": "#f8f7f5",
                        "background-dark": "#1a1a1a", /* Deep charcoal as requested */
                        "surface-dark": "#2a2a2a", /* Slightly lighter charcoal for cards */
                        "text-main": "#f5f5f5",
                        "text-secondary": "#a3a3a3",
                    },
                    fontFamily: {
                        "display": ["Inter", "sans-serif"]
                    },
                    borderRadius: {"DEFAULT": "0.25rem", "lg": "0.5rem", "xl": "0.75rem", "full": "9999px"},
                },
            },
        }
    </script>
<style>
    body {
      min-height: max(884px, 100dvh);
    }
  </style>
  </head>
<body class="bg-background-dark font-display antialiased text-text-main">
<div class="relative flex h-full min-h-screen w-full flex-col overflow-x-hidden max-w-md mx-auto border-x border-surface-dark">
<!-- Header / Navigation -->
<div class="flex items-center justify-between p-4 pt-8 sticky top-0 z-10 bg-background-dark/95 backdrop-blur-sm">
<button class="flex items-center justify-center p-2 rounded-full text-text-main hover:bg-surface-dark transition-colors">
<span class="material-symbols-outlined">arrow_back</span>
</button>
<h1 class="text-lg font-bold tracking-tight">Profile</h1>
<button class="flex items-center justify-center p-2 rounded-full text-text-main hover:bg-surface-dark transition-colors">
<span class="material-symbols-outlined">more_vert</span>
</button>
</div>
<!-- Profile Hero Section -->
<div class="flex flex-col items-center px-6 py-6 gap-6">
<!-- Avatar with ring -->
<div class="relative group">
<div class="absolute -inset-1 rounded-full bg-gradient-to-tr from-primary to-orange-400 opacity-75 blur-sm transition group-hover:opacity-100"></div>
<div class="relative h-28 w-28 rounded-full border-4 border-background-dark bg-surface-dark bg-cover bg-center" data-alt="Portrait of a young woman smiling" style="background-image: url('https://lh3.googleusercontent.com/aida-public/AB6AXuAj4ZuQ59tIxYIB1C6z3-AlqAd4ajFBYWW3mekbQmQLTtbfnAIwdKtTfb1F-Nb7H5PjUr4_an0VSwjMskg741ou3ANlMqn4BZzXXHV2gmWLuDMG1cAe402ho5lz9a9nLNxPTIwoKODR4VOW2O0icz6x0hre6VHdmzAmSPvNm-oVDjjhP6BFRRQ23bs3schQJyxoFwV3UHU_2vvKicJqXvqq3WE5hDloDCVptJVQK2w5GDCJxK7O0AvozhY9-x8WoGIyhSP3i_-4WVg');">
</div>
<button class="absolute bottom-0 right-0 flex h-8 w-8 items-center justify-center rounded-full bg-primary text-white border-2 border-background-dark">
<span class="material-symbols-outlined text-sm">edit</span>
</button>
</div>
<!-- Name and Status -->
<div class="text-center space-y-1">
<h2 class="text-2xl font-bold text-text-main">Alex Johnson</h2>
<p class="text-sm font-medium text-primary">Mastering Spanish</p>
</div>
<!-- Stats Row -->
<div class="grid grid-cols-2 gap-4 w-full mt-2">
<div class="flex flex-col items-center justify-center rounded-xl bg-surface-dark p-4 border border-white/5">
<div class="flex items-center gap-2 mb-1 text-primary">
<span class="material-symbols-outlined text-[20px]">school</span>
</div>
<span class="text-2xl font-bold text-text-main">42</span>
<span class="text-xs font-medium text-text-secondary uppercase tracking-wider">Lessons</span>
</div>
<div class="flex flex-col items-center justify-center rounded-xl bg-surface-dark p-4 border border-white/5">
<div class="flex items-center gap-2 mb-1 text-primary">
<span class="material-symbols-outlined text-[20px]">bolt</span>
</div>
<span class="text-2xl font-bold text-text-main">1250</span>
<span class="text-xs font-medium text-text-secondary uppercase tracking-wider">XP Earned</span>
</div>
</div>
</div>
<!-- Settings Section -->
<div class="flex-1 px-4 pb-24">
<h3 class="text-sm font-semibold text-text-secondary uppercase tracking-wider mb-3 ml-2 mt-4">Preferences</h3>
<div class="flex flex-col overflow-hidden rounded-xl bg-surface-dark border border-white/5 divide-y divide-white/5">
<!-- Target Language -->
<button class="flex items-center justify-between w-full p-4 hover:bg-white/5 transition-colors group">
<div class="flex items-center gap-4">
<div class="flex items-center justify-center h-10 w-10 rounded-lg bg-background-dark text-primary">
<span class="material-symbols-outlined">language</span>
</div>
<div class="text-left">
<p class="text-base font-medium text-text-main">Target Language</p>
<p class="text-xs text-text-secondary">Spanish (Intermediate)</p>
</div>
</div>
<span class="material-symbols-outlined text-text-secondary group-hover:text-primary transition-colors">chevron_right</span>
</button>
<!-- Theme Toggle -->
<div class="flex items-center justify-between w-full p-4">
<div class="flex items-center gap-4">
<div class="flex items-center justify-center h-10 w-10 rounded-lg bg-background-dark text-primary">
<span class="material-symbols-outlined">dark_mode</span>
</div>
<div class="text-left">
<p class="text-base font-medium text-text-main">Dark Theme</p>
<p class="text-xs text-text-secondary">Adjust app appearance</p>
</div>
</div>
<!-- Toggle Switch -->
<label class="relative inline-flex items-center cursor-pointer">
<input checked="" class="sr-only peer" type="checkbox" value=""/>
<div class="w-11 h-6 bg-gray-700 peer-focus:outline-none peer-focus:ring-2 peer-focus:ring-primary/50 rounded-full peer peer-checked:after:translate-x-full rtl:peer-checked:after:-translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:start-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-primary"></div>
</label>
</div>
<!-- Notifications -->
<button class="flex items-center justify-between w-full p-4 hover:bg-white/5 transition-colors group">
<div class="flex items-center gap-4">
<div class="flex items-center justify-center h-10 w-10 rounded-lg bg-background-dark text-primary">
<span class="material-symbols-outlined">notifications</span>
</div>
<div class="text-left">
<p class="text-base font-medium text-text-main">Notifications</p>
<p class="text-xs text-text-secondary">Daily reminders on</p>
</div>
</div>
<span class="material-symbols-outlined text-text-secondary group-hover:text-primary transition-colors">chevron_right</span>
</button>
</div>
<h3 class="text-sm font-semibold text-text-secondary uppercase tracking-wider mb-3 ml-2 mt-8">Account</h3>
<div class="flex flex-col overflow-hidden rounded-xl bg-surface-dark border border-white/5 divide-y divide-white/5">
<!-- Account Settings -->
<button class="flex items-center justify-between w-full p-4 hover:bg-white/5 transition-colors group">
<div class="flex items-center gap-4">
<div class="flex items-center justify-center h-10 w-10 rounded-lg bg-background-dark text-primary">
<span class="material-symbols-outlined">person</span>
</div>
<p class="text-base font-medium text-text-main">Account Details</p>
</div>
<span class="material-symbols-outlined text-text-secondary group-hover:text-primary transition-colors">chevron_right</span>
</button>
<!-- Subscription -->
<button class="flex items-center justify-between w-full p-4 hover:bg-white/5 transition-colors group">
<div class="flex items-center gap-4">
<div class="flex items-center justify-center h-10 w-10 rounded-lg bg-background-dark text-primary">
<span class="material-symbols-outlined">workspace_premium</span>
</div>
<div class="text-left">
<p class="text-base font-medium text-text-main">Subscription</p>
<p class="text-xs text-primary">Pro Plan Active</p>
</div>
</div>
<span class="material-symbols-outlined text-text-secondary group-hover:text-primary transition-colors">chevron_right</span>
</button>
<!-- Help & Support -->
<button class="flex items-center justify-between w-full p-4 hover:bg-white/5 transition-colors group">
<div class="flex items-center gap-4">
<div class="flex items-center justify-center h-10 w-10 rounded-lg bg-background-dark text-primary">
<span class="material-symbols-outlined">help</span>
</div>
<p class="text-base font-medium text-text-main">Help &amp; Support</p>
</div>
<span class="material-symbols-outlined text-text-secondary group-hover:text-primary transition-colors">chevron_right</span>
</button>
<!-- Sign Out -->
<button class="flex items-center justify-between w-full p-4 hover:bg-white/5 transition-colors group">
<div class="flex items-center gap-4">
<div class="flex items-center justify-center h-10 w-10 rounded-lg bg-background-dark text-red-500">
<span class="material-symbols-outlined">logout</span>
</div>
<p class="text-base font-medium text-red-500">Sign Out</p>
</div>
</button>
</div>
<p class="text-center text-xs text-text-secondary mt-8">Version 2.4.1</p>
</div>
<!-- Bottom Navigation Bar -->
<div class="fixed bottom-0 left-0 right-0 z-50 border-t border-white/10 bg-surface-dark/95 backdrop-blur-lg px-4 pb-6 pt-2 max-w-md mx-auto">
<div class="flex justify-between items-center">
<a class="flex flex-1 flex-col items-center justify-end gap-1 text-text-secondary hover:text-primary transition-colors" href="#">
<div class="flex h-6 items-center justify-center">
<span class="material-symbols-outlined text-[24px]">school</span>
</div>
<p class="text-[10px] font-medium leading-normal tracking-[0.015em]">Learn</p>
</a>
<a class="flex flex-1 flex-col items-center justify-end gap-1 text-text-secondary hover:text-primary transition-colors" href="#">
<div class="flex h-6 items-center justify-center">
<span class="material-symbols-outlined text-[24px]">history_edu</span>
</div>
<p class="text-[10px] font-medium leading-normal tracking-[0.015em]">Review</p>
</a>
<a class="flex flex-1 flex-col items-center justify-end gap-1 text-primary" href="#">
<div class="flex h-6 items-center justify-center relative">
<span class="material-symbols-outlined text-[24px] font-variation-settings-'FILL'1">person</span>
<span class="absolute -top-1 -right-1 h-2 w-2 rounded-full bg-primary"></span>
</div>
<p class="text-[10px] font-medium leading-normal tracking-[0.015em]">Profile</p>
</a>
<a class="flex flex-1 flex-col items-center justify-end gap-1 text-text-secondary hover:text-primary transition-colors" href="#">
<div class="flex h-6 items-center justify-center">
<span class="material-symbols-outlined text-[24px]">leaderboard</span>
</div>
<p class="text-[10px] font-medium leading-normal tracking-[0.015em]">Leaderboard</p>
</a>
</div>
</div>
</div>
</body></html>

<!-- Splash Screen Dark Mode -->
<!DOCTYPE html>

<html lang="en"><head>
<meta charset="utf-8"/>
<meta content="width=device-width, initial-scale=1.0" name="viewport"/>
<title>Speak Confidently - Splash Screen</title>
<script src="https://cdn.tailwindcss.com?plugins=forms,container-queries"></script>
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&amp;display=swap" rel="stylesheet"/>
<link href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:wght,FILL@100..700,0..1&amp;display=swap" rel="stylesheet"/>
<link href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:wght,FILL@100..700,0..1&amp;display=swap" rel="stylesheet"/>
<script id="tailwind-config">
        tailwind.config = {
            darkMode: "class",
            theme: {
                extend: {
                    colors: {
                        "primary": "#ff6a00",
                        "primary-muted": "#FF9F43",
                        "background-light": "#f8f7f5",
                        "background-dark": "#23170f",
                        "charcoal-deep": "#121212",
                        "off-white": "#F5F5F5",
                    },
                    fontFamily: {
                        "display": ["Inter", "sans-serif"],
                        "sans": ["Inter", "sans-serif"],
                    },
                    borderRadius: {"DEFAULT": "0.25rem", "lg": "0.5rem", "xl": "0.75rem", "full": "9999px"},
                },
            },
        }
    </script>
<style>
        body {
            font-family: 'Inter', sans-serif;
        }
    </style>
<style>
    body {
      min-height: max(884px, 100dvh);
    }
  </style>
  </head>
<body class="bg-charcoal-deep font-display antialiased overflow-hidden h-screen w-screen selection:bg-primary selection:text-white">
<!-- Splash Screen Container -->
<main class="relative flex flex-col h-full w-full items-center justify-center p-6">
<!-- Background Pattern (Subtle) -->
<div class="absolute inset-0 z-0 opacity-10 pointer-events-none" style="background-image: radial-gradient(#FF9F43 1px, transparent 1px); background-size: 32px 32px;">
</div>
<!-- Content Wrapper -->
<div class="relative z-10 flex flex-col items-center gap-6 animate-fade-in-up">
<!-- Logo Container -->
<div class="relative flex items-center justify-center">
<!-- Outer Glow/Halo for depth -->
<div class="absolute -inset-4 rounded-full bg-primary-muted/10 blur-xl"></div>
<!-- Logo Graphic -->
<div class="relative flex items-center justify-center w-24 h-24 sm:w-32 sm:h-32">
<!-- Speech Bubble Shape -->
<svg class="w-full h-full drop-shadow-lg" fill="none" viewbox="0 0 200 200" xmlns="http://www.w3.org/2000/svg">
<path d="M100 20C55.8172 20 20 52.2386 20 92C20 113.882 30.7305 133.476 48.0674 146.963C47.284 153.649 44.4075 163.662 38.8354 171.185C37.0372 173.614 39.4678 176.68 42.1884 175.409C57.4988 168.257 69.8398 160.316 76.5451 155.332C83.9248 158.337 91.8021 160 100 160C144.183 160 180 127.761 180 88C180 48.2386 144.183 20 100 20Z" fill="#FF9F43"></path>
<!-- Stylized 'a' cutout -->
<path d="M100 65C89.5 65 81 73.5 81 84C81 94.5 89.5 103 100 103C105 103 109.5 101 113 98V103H119V84C119 73.5 110.5 65 100 65ZM100 97C92.8 97 87 91.2 87 84C87 76.8 92.8 71 100 71C107.2 71 113 76.8 113 84C113 91.2 107.2 97 100 97Z" fill="#121212"></path>
</svg>
</div>
</div>
<!-- Tagline -->
<div class="flex flex-col items-center gap-2 mt-4">
<h1 class="text-off-white tracking-tight text-3xl sm:text-4xl font-bold leading-tight text-center">
                    Speak confidently
                </h1>
<!-- Optional Loading Indicator (Subtle pulsing dots) -->
<div class="flex gap-1.5 mt-4 opacity-50">
<div class="w-1.5 h-1.5 rounded-full bg-primary-muted animate-pulse"></div>
<div class="w-1.5 h-1.5 rounded-full bg-primary-muted animate-pulse delay-75"></div>
<div class="w-1.5 h-1.5 rounded-full bg-primary-muted animate-pulse delay-150"></div>
</div>
</div>
</div>
<!-- Footer / Branding (Optional subtle positioning) -->
<div class="absolute bottom-8 text-white/20 text-xs font-medium tracking-widest uppercase">
            AI Language Tutor
        </div>
</main>
<script>
        // Simple script to demonstrate the loading state logic if this were a real app
        // No heavy JS logic, just for display purposes
    </script>
</body></html>

<!-- Dashboard Light Mode -->
<!DOCTYPE html>

<html lang="en"><head>
<meta charset="utf-8"/>
<meta content="width=device-width, initial-scale=1.0" name="viewport"/>
<title>Language Tutor Dashboard</title>
<!-- Tailwind CSS -->
<script src="https://cdn.tailwindcss.com?plugins=forms,container-queries"></script>
<!-- Google Fonts -->
<link href="https://fonts.googleapis.com" rel="preconnect"/>
<link crossorigin="" href="https://fonts.gstatic.com" rel="preconnect"/>
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&amp;display=swap" rel="stylesheet"/>
<!-- Material Symbols -->
<link href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:wght,FILL@100..700,0..1&amp;display=swap" rel="stylesheet"/>
<link href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:wght,FILL@100..700,0..1&amp;display=swap" rel="stylesheet"/>
<!-- Theme Configuration -->
<script id="tailwind-config">
        tailwind.config = {
            darkMode: "class",
            theme: {
                extend: {
                    colors: {
                        "primary": "#ff6a00",
                        "background-light": "#ffffff", /* Using pure white as requested for main bg */
                        "background-subtle": "#f8f7f5", /* Subtle off-white for secondary areas */
                        "background-dark": "#23170f",
                        "charcoal": "#181410",
                        "charcoal-muted": "#8d715e",
                    },
                    fontFamily: {
                        "display": ["Inter", "sans-serif"]
                    },
                    borderRadius: {"DEFAULT": "0.5rem", "lg": "0.75rem", "xl": "1rem", "2xl": "1.5rem", "full": "9999px"},
                },
            },
        }
    </script>
<style>
        /* Custom scrollbar hiding for cleaner mobile look */
        .no-scrollbar::-webkit-scrollbar {
            display: none;
        }
        .no-scrollbar {
            -ms-overflow-style: none;
            scrollbar-width: none;
        }
    </style>
<style>
    body {
      min-height: max(884px, 100dvh);
    }
  </style>
  </head>
<body class="bg-background-light dark:bg-background-dark font-display text-charcoal antialiased overflow-x-hidden">
<div class="relative flex h-full min-h-screen w-full flex-col max-w-md mx-auto shadow-2xl bg-white">
<!-- Header -->
<header class="flex items-center justify-between px-6 pt-12 pb-6 bg-white sticky top-0 z-10">
<div class="flex-1">
<p class="text-charcoal-muted text-sm font-medium mb-1">Good morning,</p>
<h1 class="text-charcoal text-2xl font-bold leading-tight tracking-tight">Hi Anatol,<br/>ready to learn?</h1>
</div>
<div class="flex items-center gap-1.5 bg-orange-50 px-3 py-1.5 rounded-full border border-orange-100 shadow-sm">
<span class="material-symbols-outlined text-primary text-[20px] font-variation-settings-'FILL'-1">local_fire_department</span>
<p class="text-primary text-sm font-bold leading-normal">12</p>
</div>
</header>
<!-- Main Content Scroll Area -->
<main class="flex-1 px-6 pb-24 overflow-y-auto no-scrollbar">
<!-- Hero Card: Continue Lesson -->
<div class="mt-2 w-full group relative overflow-hidden rounded-2xl shadow-[0_8px_30px_rgb(0,0,0,0.06)] bg-white border border-gray-100 transition-transform active:scale-[0.98]">
<div class="relative h-48 w-full">
<div class="absolute inset-0 bg-cover bg-center" data-alt="Cozy cafe table with coffee and croissant" style="background-image: url('https://lh3.googleusercontent.com/aida-public/AB6AXuB5xpc-utQfFTQDyLuEccWQiTCl0hfS1jvb_n42elbZeqE4YBQClD-s4iuG5lekf9hHfrNlBOtL4JdqUKU5majAZNrCLAK4MZkqse7ao6WuLJCihCvlp33jUYqge30zaebMZq68ZdCjpms71aFucabXeLDK1NwfjuA6mxbF0OcqLw41dcYvtCM7NqIB8d4US6s0sQNExBd3AVkYSsLt8uO9BmbpneKJsFA5XJsELvn365Qcdxn8oXp9wBun_AFjT0hOJ1hX-k_N1hg');"></div>
<div class="absolute inset-0 bg-gradient-to-t from-black/60 to-transparent"></div>
<div class="absolute bottom-4 left-4 right-4">
<span class="inline-block px-2 py-1 mb-2 text-xs font-semibold text-white bg-primary rounded-md">Current Lesson</span>
<h2 class="text-white text-xl font-bold leading-tight">Ordering Coffee in French</h2>
</div>
</div>
<div class="p-5">
<div class="flex items-center justify-between mb-2">
<span class="text-xs font-medium text-charcoal-muted">Lesson 3 of 5</span>
<span class="text-xs font-bold text-primary">60%</span>
</div>
<div class="relative h-2 w-full rounded-full bg-gray-100 overflow-hidden mb-5">
<div class="absolute top-0 left-0 h-full rounded-full bg-primary transition-all duration-500" style="width: 60%;"></div>
</div>
<button class="w-full py-3.5 px-4 bg-primary hover:bg-orange-600 active:bg-orange-700 text-white rounded-xl font-semibold shadow-md shadow-orange-200 flex items-center justify-center gap-2 transition-colors">
<span class="material-symbols-outlined text-[20px]">play_arrow</span>
<span>Resume Lesson</span>
</button>
</div>
</div>
<!-- Stats Row -->
<div class="grid grid-cols-2 gap-4 mt-8">
<div class="p-4 rounded-xl bg-background-subtle border border-gray-100 flex flex-col items-start gap-2">
<div class="h-8 w-8 rounded-full bg-blue-50 flex items-center justify-center text-blue-500">
<span class="material-symbols-outlined text-[20px]">school</span>
</div>
<div>
<p class="text-2xl font-bold text-charcoal">1,204</p>
<p class="text-xs text-charcoal-muted font-medium">Words Learned</p>
</div>
</div>
<div class="p-4 rounded-xl bg-background-subtle border border-gray-100 flex flex-col items-start gap-2">
<div class="h-8 w-8 rounded-full bg-purple-50 flex items-center justify-center text-purple-500">
<span class="material-symbols-outlined text-[20px]">military_tech</span>
</div>
<div>
<p class="text-2xl font-bold text-charcoal">850</p>
<p class="text-xs text-charcoal-muted font-medium">Total XP</p>
</div>
</div>
</div>
<!-- Daily Goal Section -->
<div class="mt-8">
<div class="flex items-center justify-between mb-4">
<h3 class="text-lg font-bold text-charcoal">Daily Goal</h3>
<button class="text-primary text-sm font-medium">Edit</button>
</div>
<div class="flex items-center p-4 bg-white rounded-xl border border-gray-100 shadow-sm">
<div class="relative h-12 w-12 mr-4 flex-shrink-0">
<svg class="transform -rotate-90 w-12 h-12">
<circle class="text-gray-100" cx="24" cy="24" fill="transparent" r="20" stroke="currentColor" stroke-width="4"></circle>
<circle class="text-primary" cx="24" cy="24" fill="transparent" r="20" stroke="currentColor" stroke-dasharray="125.6" stroke-dashoffset="31.4" stroke-width="4"></circle>
</svg>
<div class="absolute inset-0 flex items-center justify-center">
<span class="text-xs font-bold text-charcoal">75%</span>
</div>
</div>
<div class="flex-1">
<p class="text-sm font-bold text-charcoal">30 mins / day</p>
<p class="text-xs text-charcoal-muted">Keep it up! You're almost there.</p>
</div>
</div>
</div>
<!-- Suggested Practice -->
<div class="mt-8 mb-4">
<h3 class="text-lg font-bold text-charcoal mb-4">Recommended for you</h3>
<div class="space-y-3">
<div class="flex items-center p-3 rounded-xl hover:bg-gray-50 transition-colors border border-transparent hover:border-gray-100 cursor-pointer">
<div class="h-10 w-10 rounded-lg bg-green-50 flex items-center justify-center text-green-600 mr-3">
<span class="material-symbols-outlined">forum</span>
</div>
<div class="flex-1">
<p class="text-sm font-bold text-charcoal">Conversation Practice</p>
<p class="text-xs text-charcoal-muted">Master greetings</p>
</div>
<span class="material-symbols-outlined text-gray-300">chevron_right</span>
</div>
<div class="flex items-center p-3 rounded-xl hover:bg-gray-50 transition-colors border border-transparent hover:border-gray-100 cursor-pointer">
<div class="h-10 w-10 rounded-lg bg-pink-50 flex items-center justify-center text-pink-500 mr-3">
<span class="material-symbols-outlined">history_edu</span>
</div>
<div class="flex-1">
<p class="text-sm font-bold text-charcoal">Review Mistakes</p>
<p class="text-xs text-charcoal-muted">12 items to review</p>
</div>
<span class="material-symbols-outlined text-gray-300">chevron_right</span>
</div>
</div>
</div>
</main>
<!-- Bottom Navigation -->
<nav class="fixed bottom-0 w-full max-w-md bg-white border-t border-gray-100 px-6 pb-6 pt-2 z-20 flex justify-between items-end">
<a class="flex flex-col items-center gap-1 min-w-[64px] group" href="#">
<div class="relative p-1 rounded-full group-hover:bg-orange-50 transition-colors">
<span class="material-symbols-outlined text-primary text-[28px] font-variation-settings-'FILL'-1">home</span>
</div>
<span class="text-[10px] font-medium text-primary">Home</span>
</a>
<a class="flex flex-col items-center gap-1 min-w-[64px] group" href="#">
<div class="relative p-1 rounded-full group-hover:bg-gray-50 transition-colors">
<span class="material-symbols-outlined text-charcoal-muted group-hover:text-charcoal text-[28px]">menu_book</span>
</div>
<span class="text-[10px] font-medium text-charcoal-muted group-hover:text-charcoal">Lessons</span>
</a>
<a class="flex flex-col items-center gap-1 min-w-[64px] group" href="#">
<div class="relative p-1 rounded-full group-hover:bg-gray-50 transition-colors">
<span class="material-symbols-outlined text-charcoal-muted group-hover:text-charcoal text-[28px]">mic</span>
</div>
<span class="text-[10px] font-medium text-charcoal-muted group-hover:text-charcoal">Voice</span>
</a>
<a class="flex flex-col items-center gap-1 min-w-[64px] group" href="#">
<div class="relative p-1 rounded-full group-hover:bg-gray-50 transition-colors">
<span class="material-symbols-outlined text-charcoal-muted group-hover:text-charcoal text-[28px]">person</span>
</div>
<span class="text-[10px] font-medium text-charcoal-muted group-hover:text-charcoal">Profile</span>
</a>
</nav>
</div>
</body></html>

<!-- Voice Mode Light Mode -->
<!DOCTYPE html>

<html lang="en"><head>
<meta charset="utf-8"/>
<meta content="width=device-width, initial-scale=1.0" name="viewport"/>
<title>Voice Mode Light Mode</title>
<script src="https://cdn.tailwindcss.com?plugins=forms,container-queries"></script>
<link href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:wght,FILL@100..700,0..1&amp;display=swap" rel="stylesheet"/>
<link href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:wght,FILL@100..700,0..1&amp;display=swap" rel="stylesheet"/>
<script id="tailwind-config">
        tailwind.config = {
          darkMode: "class",
          theme: {
            extend: {
              colors: {
                "primary": "#ff6a00",
                "background-light": "#f8f7f5", // Keeping the requested warm white/off-white for softer look
                "background-dark": "#23170f",
              },
              fontFamily: {
                "display": ["Inter", "sans-serif"]
              },
              borderRadius: {"DEFAULT": "0.25rem", "lg": "0.5rem", "xl": "0.75rem", "full": "9999px"},
              animation: {
                'pulse-slow': 'pulse 4s cubic-bezier(0.4, 0, 0.6, 1) infinite',
                'pulse-medium': 'pulse 3s cubic-bezier(0.4, 0, 0.6, 1) infinite',
                'ripple': 'ripple 2s linear infinite',
              },
              keyframes: {
                ripple: {
                  '0%': { transform: 'scale(0.8)', opacity: '1' },
                  '100%': { transform: 'scale(2.4)', opacity: '0' },
                }
              }
            },
          },
        }
    </script>
<style>
      /* Custom animation classes for the wave effect without JS */
      .wave-container {
        position: relative;
        display: flex;
        justify-content: center;
        align-items: center;
      }
      
      .wave {
        position: absolute;
        border-radius: 50%;
        background-color: rgba(255, 106, 0, 0.15); /* Primary color low opacity */
        animation: ripple 2.5s linear infinite;
      }
      
      .wave:nth-child(1) { animation-delay: 0s; }
      .wave:nth-child(2) { animation-delay: 0.6s; }
      .wave:nth-child(3) { animation-delay: 1.2s; }
      .wave:nth-child(4) { animation-delay: 1.8s; }

      @keyframes ripple {
        0% {
          width: 80px;
          height: 80px;
          opacity: 0.8;
          border: 1px solid rgba(255, 106, 0, 0.3);
        }
        100% {
          width: 380px;
          height: 380px;
          opacity: 0;
          border: 1px solid rgba(255, 106, 0, 0);
        }
      }

      /* Core orb pulsing */
      .core-orb {
        box-shadow: 0 0 40px rgba(255, 106, 0, 0.4);
      }
    </style>
<style>
    body {
      min-height: max(884px, 100dvh);
    }
  </style>
  </head>
<body class="bg-background-light dark:bg-background-dark font-display h-screen w-full flex flex-col overflow-hidden relative selection:bg-primary selection:text-white">
<!-- Top Status Indicator (Subtle) -->
<div class="absolute top-0 w-full z-10 pt-12 flex justify-center">
<div class="flex items-center gap-2 px-4 py-1.5 bg-white/50 backdrop-blur-sm rounded-full border border-stone-100 shadow-sm dark:bg-white/5 dark:border-white/10">
<span class="relative flex h-2 w-2">
<span class="animate-ping absolute inline-flex h-full w-full rounded-full bg-primary opacity-75"></span>
<span class="relative inline-flex rounded-full h-2 w-2 bg-primary"></span>
</span>
<span class="text-xs font-medium text-stone-500 uppercase tracking-widest dark:text-stone-400">Listening</span>
</div>
</div>
<!-- Main Content: Central Visualizer -->
<div class="flex-1 flex flex-col items-center justify-center w-full relative">
<!-- Abstract Listening Avatar / Pattern Background -->
<div class="absolute inset-0 z-0 opacity-5 pointer-events-none" style="background-image: radial-gradient(#ff6a00 1px, transparent 1px); background-size: 32px 32px;">
</div>
<div class="wave-container z-10 relative">
<!-- Ripple Waves -->
<div class="wave"></div>
<div class="wave"></div>
<div class="wave"></div>
<div class="wave"></div>
<!-- Central Core Orb -->
<div class="relative z-20 w-32 h-32 bg-gradient-to-br from-primary to-[#ff9100] rounded-full flex items-center justify-center core-orb transition-transform duration-1000 ease-in-out transform hover:scale-105">
<!-- Inner visual detail -->
<div class="w-24 h-24 bg-white/20 rounded-full blur-md"></div>
<span class="material-symbols-outlined absolute text-white/90 !text-[48px] animate-pulse">
                    graphic_eq
                </span>
</div>
</div>
<!-- Conversational Context (Optional helpful text) -->
<div class="mt-16 text-center z-10 opacity-60">
<p class="text-stone-800 dark:text-stone-200 text-lg font-light">"How do you say 'Coffee' in Spanish?"</p>
</div>
</div>
<!-- Bottom Controls -->
<div class="flex justify-center items-end pb-12 px-6 z-20">
<!-- End Call Button -->
<button class="group relative flex items-center justify-center w-20 h-20 bg-[#23170f] dark:bg-white text-white dark:text-[#23170f] rounded-full shadow-lg hover:shadow-xl transition-all duration-300 hover:scale-105 active:scale-95 focus:outline-none focus:ring-4 focus:ring-stone-200 dark:focus:ring-stone-700">
<div class="absolute inset-0 rounded-full border border-white/10 dark:border-black/5 group-hover:border-primary/50 transition-colors"></div>
<span class="material-symbols-outlined !text-[32px] group-hover:text-red-500 transition-colors">
                call_end
            </span>
</button>
</div>
<!-- Background Decoration for Visual Depth -->
<div class="absolute bottom-0 left-0 w-full h-1/3 bg-gradient-to-t from-white via-white/80 to-transparent dark:from-background-dark dark:via-background-dark/80 pointer-events-none"></div>
</body></html>

<!-- Splash Screen Light Mode -->
<!DOCTYPE html>

<html lang="en"><head>
<meta charset="utf-8"/>
<meta content="width=device-width, initial-scale=1.0" name="viewport"/>
<title>Splash Screen Light Mode</title>
<script src="https://cdn.tailwindcss.com?plugins=forms,container-queries"></script>
<link href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:wght,FILL@100..700,0..1&amp;display=swap" rel="stylesheet"/>
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&amp;display=swap" rel="stylesheet"/>
<link href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:wght,FILL@100..700,0..1&amp;display=swap" rel="stylesheet"/>
<script id="tailwind-config">
        tailwind.config = {
            darkMode: "class",
            theme: {
                extend: {
                    colors: {
                        "primary": "#ff6a00",
                        "background-light": "#ffffff", // Overridden to pure white as per splash screen request
                        "background-dark": "#23170f",
                    },
                    fontFamily: {
                        "display": ["Inter", "sans-serif"]
                    },
                    borderRadius: {"DEFAULT": "0.25rem", "lg": "0.5rem", "xl": "0.75rem", "full": "9999px"},
                },
            },
        }
    </script>
<style>
        /* Custom logo shape styling */
        .logo-bubble {
            border-bottom-left-radius: 0;
        }
    </style>
<style>
    body {
      min-height: max(884px, 100dvh);
    }
  </style>
  </head>
<body class="bg-background-light dark:bg-background-dark min-h-screen flex flex-col items-center justify-center font-display antialiased selection:bg-primary/20">
<!-- Main Container -->
<main class="relative flex h-full w-full flex-col items-center justify-center p-6 flex-grow">
<!-- Logo Section -->
<div class="flex flex-col items-center justify-center gap-6 mb-8 animate-pulse-slow">
<!-- Custom CSS Logo Icon representing 'a' + speech bubble -->
<div class="relative flex items-center justify-center">
<!-- Speech Bubble Shape -->
<div class="w-24 h-24 sm:w-32 sm:h-32 bg-primary rounded-[2rem] logo-bubble flex items-center justify-center shadow-lg shadow-primary/20 transform rotate-12">
<!-- The stylized 'a' inside -->
<span class="text-white text-6xl sm:text-7xl font-bold -rotate-12 pb-1 pr-1">a</span>
</div>
<!-- Decorative elements for polish -->
<div class="absolute -top-2 -right-2 w-4 h-4 bg-primary/40 rounded-full animate-bounce delay-75"></div>
<div class="absolute -bottom-4 -left-2 w-3 h-3 bg-primary/30 rounded-full animate-bounce delay-150"></div>
</div>
<!-- App Name (Optional context filler) -->
<h1 class="text-3xl sm:text-4xl font-bold text-[#181410] dark:text-white tracking-tight mt-4">
                Lingo<span class="text-primary">AI</span>
</h1>
</div>
<!-- Tagline Section -->
<div class="flex flex-col items-center gap-2 text-center">
<h2 class="text-[#333333] dark:text-gray-300 tracking-normal text-lg sm:text-xl font-medium leading-relaxed px-4">
                Speak confidently
            </h2>
</div>
</main>
<!-- Bottom Spacer for Home Indicator Area -->
<div class="h-8 w-full"></div>
</body></html>

<!-- Login Dark Mode -->
<!DOCTYPE html>

<html lang="en"><head>
<meta charset="utf-8"/>
<meta content="width=device-width, initial-scale=1.0" name="viewport"/>
<title>Login Dark Mode</title>
<link href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:wght,FILL@100..700,0..1&amp;display=swap" rel="stylesheet"/>
<link href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:wght,FILL@100..700,0..1&amp;display=swap" rel="stylesheet"/>
<script src="https://cdn.tailwindcss.com?plugins=forms,container-queries"></script>
<script id="tailwind-config">
        tailwind.config = {
            darkMode: "class",
            theme: {
                extend: {
                    colors: {
                        "primary": "#ff6a00", // Global primary
                        "primary-muted": "#FF9F43", // Specific requested muted amber
                        "background-light": "#f8f7f5",
                        "background-dark": "#121212", // Overriding config to match specific deep charcoal request
                        "surface-dark": "#1E1E1E", // Slightly lighter for inputs
                        "text-off-white": "#F5F5F5",
                        "text-muted": "#A1A1AA",
                    },
                    fontFamily: {
                        "display": ["Inter", "sans-serif"]
                    },
                    borderRadius: {"DEFAULT": "0.25rem", "lg": "0.5rem", "xl": "0.75rem", "full": "9999px"},
                },
            },
        }
    </script>
<style>
        body {
            font-family: 'Inter', sans-serif;
        }
        /* Custom scrollbar hide for cleaner mobile look */
        .no-scrollbar::-webkit-scrollbar {
            display: none;
        }
        .no-scrollbar {
            -ms-overflow-style: none;
            scrollbar-width: none;
        }
    </style>
<style>
    body {
      min-height: max(884px, 100dvh);
    }
  </style>
  </head>
<body class="bg-background-dark text-text-off-white font-display antialiased min-h-screen flex flex-col items-center justify-center selection:bg-primary selection:text-white">
<!-- Main Container: Mobile Form Factor -->
<div class="relative w-full max-w-[420px] h-full min-h-screen flex flex-col p-6 mx-auto">
<!-- Status Bar Area Spacer -->
<div class="h-6 w-full mb-4"></div>
<!-- Header Section -->
<div class="flex flex-col items-center justify-center mt-8 mb-10">
<!-- Logo Placeholder -->
<div class="w-16 h-16 rounded-2xl bg-gradient-to-br from-primary to-primary-muted flex items-center justify-center shadow-lg shadow-primary/20 mb-6" data-alt="App logo with minimalist abstract letter A">
<span class="material-symbols-outlined text-white text-4xl">translate</span>
</div>
<h1 class="text-3xl font-bold tracking-tight text-center mb-2">Welcome Back</h1>
<p class="text-text-muted text-center text-sm font-normal">Unlock your language potential today.</p>
</div>
<!-- Form Section -->
<form class="w-full flex flex-col gap-5">
<!-- Email Input -->
<div class="flex flex-col gap-2">
<label class="text-sm font-medium text-text-off-white ml-1" for="email">Email Address</label>
<div class="relative group">
<div class="absolute inset-y-0 left-0 pl-4 flex items-center pointer-events-none">
<span class="material-symbols-outlined text-text-muted group-focus-within:text-primary transition-colors duration-200">mail</span>
</div>
<input class="w-full bg-surface-dark border border-white/10 text-text-off-white text-base rounded-xl focus:ring-2 focus:ring-primary/50 focus:border-primary block pl-11 p-4 placeholder-text-muted/50 transition-all duration-200" id="email" placeholder="hello@example.com" required="" type="email"/>
</div>
</div>
<!-- Password Input -->
<div class="flex flex-col gap-2">
<div class="flex justify-between items-center ml-1">
<label class="text-sm font-medium text-text-off-white" for="password">Password</label>
<a class="text-xs font-medium text-primary hover:text-primary-muted transition-colors" href="#">Forgot Password?</a>
</div>
<div class="relative group">
<div class="absolute inset-y-0 left-0 pl-4 flex items-center pointer-events-none">
<span class="material-symbols-outlined text-text-muted group-focus-within:text-primary transition-colors duration-200">lock</span>
</div>
<input class="w-full bg-surface-dark border border-white/10 text-text-off-white text-base rounded-xl focus:ring-2 focus:ring-primary/50 focus:border-primary block pl-11 pr-12 p-4 placeholder-text-muted/50 transition-all duration-200" id="password" placeholder="Enter your password" required="" type="password"/>
<button class="absolute inset-y-0 right-0 pr-4 flex items-center text-text-muted hover:text-text-off-white transition-colors" type="button">
<span class="material-symbols-outlined text-[20px]">visibility_off</span>
</button>
</div>
</div>
<!-- Primary Action Button -->
<button class="mt-4 w-full bg-primary-muted hover:bg-primary text-background-dark font-bold text-lg py-4 px-6 rounded-xl shadow-lg shadow-primary-muted/20 hover:shadow-primary-muted/40 transform active:scale-[0.98] transition-all duration-200 flex items-center justify-center gap-2" type="submit">
                Get Started
                <span class="material-symbols-outlined text-xl font-bold">arrow_forward</span>
</button>
</form>
<!-- Spacer -->
<div class="flex-grow"></div>
<!-- Social Login Section -->
<div class="w-full flex flex-col items-center gap-6 mb-8 mt-8">
<div class="relative w-full flex items-center justify-center">
<div class="absolute inset-0 flex items-center">
<div class="w-full border-t border-white/10"></div>
</div>
<span class="relative bg-background-dark px-4 text-xs text-text-muted uppercase tracking-wider">Or continue with</span>
</div>
<div class="flex items-center justify-center gap-4 w-full">
<!-- Google Button -->
<button class="flex-1 h-14 bg-surface-dark border border-white/10 hover:bg-white/5 rounded-xl flex items-center justify-center transition-colors duration-200 group">
<!-- Simple Google G Icon Representation -->
<svg class="w-6 h-6 text-text-off-white group-hover:scale-110 transition-transform duration-200" fill="currentColor" viewbox="0 0 24 24">
<path d="M12.48 10.92v3.28h7.84c-.24 1.84-.853 3.187-1.787 4.133-1.147 1.147-2.933 2.4-6.053 2.4-4.827 0-8.6-3.893-8.6-8.72s3.773-8.72 8.6-8.72c2.6 0 4.507 1.027 5.907 2.347l2.307-2.307C18.747 1.44 16.133 0 12.48 0 5.867 0 .533 5.347.533 12s5.333 12 11.947 12c3.507 0 6.187-1.16 8.24-3.28 2.08-2.08 2.72-5.013 2.72-7.427 0-.733-.08-1.44-.213-2.12h-10.74z"></path>
</svg>
</button>
<!-- Apple Button -->
<button class="flex-1 h-14 bg-surface-dark border border-white/10 hover:bg-white/5 rounded-xl flex items-center justify-center transition-colors duration-200 group">
<svg class="w-6 h-6 text-text-off-white group-hover:scale-110 transition-transform duration-200" fill="currentColor" viewbox="0 0 24 24">
<path d="M17.05 20.28c-.98.95-2.05.8-3.08.35-1.09-.46-2.09-.48-3.24 0-1.44.62-2.2.44-3.06-.35C2.79 15.25 3.51 7.59 9.05 7.31c1.35.07 2.29.74 3.08.74 1.18 0 2.45-1.11 4.1-1.11 1.05.06 1.88.45 2.5 1.03-2.2 1.5-1.8 4.7 0 5.68-.52 2.72-2.22 4.49-2.93 6.63zm-5.41-9.37c-.9-3.8 3.2-6.37 3.36-6.37.1 2.9-3.36 4.7-3.36 6.37z"></path>
</svg>
</button>
<!-- Facebook Button -->
<button class="flex-1 h-14 bg-surface-dark border border-white/10 hover:bg-white/5 rounded-xl flex items-center justify-center transition-colors duration-200 group">
<svg class="w-6 h-6 text-text-off-white group-hover:scale-110 transition-transform duration-200" fill="currentColor" viewbox="0 0 24 24">
<path d="M24 12.073c0-6.627-5.373-12-12-12s-12 5.373-12 12c0 5.99 4.388 10.954 10.125 11.854v-8.385H7.078v-3.47h3.047V9.43c0-3.007 1.792-4.669 4.533-4.669 1.312 0 2.686.235 2.686.235v2.953H15.83c-1.491 0-1.956.925-1.956 1.874v2.25h3.328l-.532 3.47h-2.796v8.385C19.612 23.027 24 18.062 24 12.073z"></path>
</svg>
</button>
</div>
</div>
<!-- Footer -->
<div class="text-center pb-2">
<p class="text-text-muted text-sm">
                Don't have an account? 
                <a class="text-primary-muted font-semibold hover:text-white transition-colors" href="#">Sign up</a>
</p>
</div>
</div>
</body></html>

<!-- Voice Mode Dark Mode -->
<!DOCTYPE html>

<html lang="en"><head>
<meta charset="utf-8"/>
<meta content="width=device-width, initial-scale=1.0" name="viewport"/>
<title>AI Tutor - Voice Mode</title>
<script src="https://cdn.tailwindcss.com?plugins=forms,container-queries"></script>
<link href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:wght,FILL@100..700,0..1&amp;display=swap" rel="stylesheet"/>
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;700&amp;display=swap" rel="stylesheet"/>
<link href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:wght,FILL@100..700,0..1&amp;display=swap" rel="stylesheet"/>
<script id="tailwind-config">
        tailwind.config = {
            darkMode: "class",
            theme: {
                extend: {
                    colors: {
                        "primary": "#ff6a00",
                        "primary-muted": "#FF9F43",
                        "background-light": "#f8f7f5",
                        "background-dark": "#23170f",
                        "charcoal": "#1A1A1A", 
                    },
                    fontFamily: {
                        "display": ["Inter", "sans-serif"]
                    },
                    borderRadius: {"DEFAULT": "0.25rem", "lg": "0.5rem", "xl": "0.75rem", "full": "9999px"},
                },
            },
        }
    </script>
<style>
        /* Custom wave animation simulation using gradients */
        .wave-bg {
            background: radial-gradient(circle, rgba(255, 159, 67, 0.2) 0%, rgba(255, 159, 67, 0.05) 40%, transparent 70%);
        }
        .wave-core {
            background: radial-gradient(circle, rgba(255, 159, 67, 0.8) 0%, rgba(255, 106, 0, 0.6) 100%);
            box-shadow: 0 0 60px rgba(255, 106, 0, 0.4);
        }
    </style>
<style>
    body {
      min-height: max(884px, 100dvh);
    }
  </style>
  </head>
<body class="bg-charcoal font-display text-white antialiased overflow-hidden h-screen w-full flex flex-col items-center relative">
<!-- Subtle Background Noise/Texture Simulation (CSS Gradient) -->
<div class="absolute inset-0 bg-[radial-gradient(circle_at_top,_var(--tw-gradient-stops))] from-white/5 via-transparent to-transparent pointer-events-none"></div>
<!-- Status Bar Area (Simulated for iOS context) -->
<div class="w-full flex justify-between items-center px-6 pt-6 pb-2 z-20">
<!-- Close/Back -->
<button class="flex items-center justify-center size-10 rounded-full bg-white/10 hover:bg-white/20 transition-colors text-white/70">
<span class="material-symbols-outlined text-[24px]">expand_more</span>
</button>
<!-- Timer / Status -->
<div class="flex items-center gap-2 px-3 py-1 rounded-full bg-white/5 border border-white/5 backdrop-blur-sm">
<div class="size-2 rounded-full bg-red-500 animate-pulse"></div>
<span class="text-xs font-medium tracking-wide text-white/60 font-mono">04:12</span>
</div>
<!-- Settings / Menu -->
<button class="flex items-center justify-center size-10 rounded-full bg-white/10 hover:bg-white/20 transition-colors text-white/70">
<span class="material-symbols-outlined text-[20px]">more_horiz</span>
</button>
</div>
<!-- Main Content: Central Visualization -->
<div class="flex-1 w-full flex flex-col items-center justify-center relative z-10">
<!-- Outer Wave Ripples (Decorative) -->
<div class="absolute inset-0 flex items-center justify-center pointer-events-none">
<div class="w-[500px] h-[500px] rounded-full border border-primary/5 scale-110 opacity-20"></div>
<div class="absolute w-[400px] h-[400px] rounded-full border border-primary/10 scale-100 opacity-30"></div>
<div class="absolute w-[300px] h-[300px] rounded-full border border-primary/20 scale-95 opacity-40"></div>
</div>
<!-- Active Speaker Visualization -->
<div class="relative flex items-center justify-center">
<!-- Glow Effect -->
<div class="absolute size-64 rounded-full wave-bg blur-3xl animate-pulse"></div>
<!-- Core Visualizer -->
<div class="relative size-32 rounded-full wave-core flex items-center justify-center">
<!-- Inner texture/icon abstract -->
<div class="size-28 rounded-full border border-white/20 bg-white/5 backdrop-blur-sm flex items-center justify-center">
<span class="material-symbols-outlined text-white/90 text-4xl">graphic_eq</span>
</div>
</div>
</div>
<!-- AI Status Text -->
<div class="mt-12 text-center opacity-80">
<h2 class="text-xl font-medium tracking-tight text-white/90">Sarah (AI)</h2>
<p class="text-sm text-primary-muted mt-1 font-medium tracking-wide uppercase text-[10px]">Listening...</p>
</div>
<!-- Live Transcription Preview (Fading) -->
<div class="mt-8 px-8 max-w-sm text-center h-16 flex items-center justify-center">
<p class="text-lg text-white/40 leading-relaxed font-light">
                "Can you explain the difference between..."
            </p>
</div>
</div>
<!-- Bottom Controls -->
<div class="w-full pb-10 px-6 flex justify-center items-end z-20">
<!-- Control Bar Container -->
<div class="flex items-center gap-6">
<!-- Mute Toggle -->
<button class="flex items-center justify-center size-14 rounded-full bg-white/10 hover:bg-white/20 transition-all active:scale-95 text-white">
<span class="material-symbols-outlined text-[24px]">mic_off</span>
</button>
<!-- End Call (Primary Action) -->
<button class="flex items-center justify-center size-20 rounded-full bg-red-500 hover:bg-red-600 shadow-[0_0_20px_rgba(239,68,68,0.4)] transition-all active:scale-95 transform hover:-translate-y-1">
<span class="material-symbols-outlined text-white text-[32px] font-bold">call_end</span>
</button>
<!-- Speaker Toggle -->
<button class="flex items-center justify-center size-14 rounded-full bg-white/10 hover:bg-white/20 transition-all active:scale-95 text-white">
<span class="material-symbols-outlined text-[24px]">volume_up</span>
</button>
</div>
</div>
</body></html>

<!-- Login Light Mode -->
<!DOCTYPE html>

<html lang="en"><head>
<meta charset="utf-8"/>
<meta content="width=device-width, initial-scale=1.0" name="viewport"/>
<title>Login - Language Tutor</title>
<!-- Tailwind CSS -->
<script src="https://cdn.tailwindcss.com?plugins=forms,container-queries"></script>
<!-- Material Symbols -->
<link href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:wght,FILL@100..700,0..1&amp;display=swap" rel="stylesheet"/>
<!-- Fonts -->
<link href="https://fonts.googleapis.com" rel="preconnect"/>
<link crossorigin="" href="https://fonts.gstatic.com" rel="preconnect"/>
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&amp;display=swap" rel="stylesheet"/>
<link href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:wght,FILL@100..700,0..1&amp;display=swap" rel="stylesheet"/>
<!-- Theme Config -->
<script id="tailwind-config">
        tailwind.config = {
            darkMode: "class",
            theme: {
                extend: {
                    colors: {
                        "primary": "#ff6a00",
                        "primary-dark": "#e65100",
                        "background-light": "#ffffff", /* Overriding config slightly to match specific user request for white */
                        "background-dark": "#23170f",
                        "charcoal": "#333333",
                        "charcoal-light": "#4b5563",
                        "border-light": "#e5e7eb",
                    },
                    fontFamily: {
                        "display": ["Inter", "sans-serif"]
                    },
                    borderRadius: {
                        "DEFAULT": "0.375rem",
                        "lg": "0.5rem",
                        "xl": "0.75rem",
                        "full": "9999px"
                    },
                },
            },
        }
    </script>
<style>
    body {
      min-height: max(884px, 100dvh);
    }
  </style>
  </head>
<body class="bg-background-light text-charcoal font-display antialiased selection:bg-primary/20 selection:text-primary">
<div class="relative flex min-h-screen w-full flex-col overflow-hidden max-w-md mx-auto bg-white">
<!-- Header Section -->
<header class="flex flex-col items-center pt-12 pb-6 px-6">
<div class="w-16 h-16 bg-primary/10 rounded-2xl flex items-center justify-center mb-6 text-primary">
<span class="material-symbols-outlined text-4xl">translate</span>
</div>
<h1 class="text-3xl font-bold tracking-tight text-charcoal text-center mb-2">Welcome Back</h1>
<p class="text-charcoal-light text-base font-normal text-center">Continue your language journey</p>
</header>
<!-- Main Form Section -->
<main class="flex-1 px-6 flex flex-col gap-5">
<!-- Email Input -->
<div class="flex flex-col gap-2">
<label class="text-charcoal font-medium text-sm ml-1" for="email">Email Address</label>
<div class="relative group">
<div class="absolute inset-y-0 left-0 pl-4 flex items-center pointer-events-none text-gray-400 group-focus-within:text-primary transition-colors">
<span class="material-symbols-outlined text-[20px]">mail</span>
</div>
<input class="form-input block w-full rounded-lg border-border-light bg-gray-50/50 pl-11 pr-4 py-3.5 text-base text-charcoal placeholder:text-gray-400 focus:border-primary focus:ring-1 focus:ring-primary focus:bg-white transition-all shadow-sm" id="email" placeholder="hello@example.com" type="email"/>
</div>
</div>
<!-- Password Input -->
<div class="flex flex-col gap-2">
<div class="flex justify-between items-center ml-1">
<label class="text-charcoal font-medium text-sm" for="password">Password</label>
</div>
<div class="relative group">
<div class="absolute inset-y-0 left-0 pl-4 flex items-center pointer-events-none text-gray-400 group-focus-within:text-primary transition-colors">
<span class="material-symbols-outlined text-[20px]">lock</span>
</div>
<input class="form-input block w-full rounded-lg border-border-light bg-gray-50/50 pl-11 pr-12 py-3.5 text-base text-charcoal placeholder:text-gray-400 focus:border-primary focus:ring-1 focus:ring-primary focus:bg-white transition-all shadow-sm" id="password" placeholder="Enter your password" type="password"/>
<button class="absolute inset-y-0 right-0 pr-4 flex items-center text-gray-400 hover:text-charcoal transition-colors focus:outline-none" type="button">
<span class="material-symbols-outlined text-[20px]">visibility_off</span>
</button>
</div>
<div class="flex justify-end mt-1">
<a class="text-sm font-medium text-primary hover:text-primary-dark transition-colors" href="#">Forgot Password?</a>
</div>
</div>
<!-- Primary Action -->
<button class="w-full bg-primary hover:bg-primary-dark active:scale-[0.98] text-white font-semibold text-lg py-3.5 rounded-lg shadow-md shadow-primary/20 transition-all duration-200 mt-2 flex items-center justify-center gap-2">
                Get Started
                <span class="material-symbols-outlined text-xl">arrow_forward</span>
</button>
<!-- Social Login Divider -->
<div class="relative flex items-center py-4 mt-2">
<div class="flex-grow border-t border-gray-200"></div>
<span class="flex-shrink-0 mx-4 text-gray-400 text-sm font-medium">Or continue with</span>
<div class="flex-grow border-t border-gray-200"></div>
</div>
<!-- Social Buttons -->
<div class="grid grid-cols-2 gap-4">
<button class="flex items-center justify-center gap-2 w-full bg-white border border-gray-200 hover:bg-gray-50 hover:border-gray-300 text-charcoal font-medium py-3 rounded-lg transition-all active:scale-[0.98]">
<svg class="w-5 h-5" viewbox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
<path d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z" fill="#4285F4"></path>
<path d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z" fill="#34A853"></path>
<path d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z" fill="#FBBC05"></path>
<path d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z" fill="#EA4335"></path>
</svg>
                    Google
                </button>
<button class="flex items-center justify-center gap-2 w-full bg-white border border-gray-200 hover:bg-gray-50 hover:border-gray-300 text-charcoal font-medium py-3 rounded-lg transition-all active:scale-[0.98]">
<svg class="w-5 h-5" fill="currentColor" viewbox="0 0 24 24">
<path d="M17.05 20.28c-.98.95-2.05.88-3.08.38-1.09-.52-2.09-.48-3.24 0-1.44.62-2.2.44-3.06-.38C2.79 15.25 3.51 7.59 9.05 7.31c1.35.07 2.29.74 3.08.8 1.18-.1 2.69-1.01 3.93-.48 2.06.87 3.05 2.76 3.05 2.76s-1.8.87-2.13 3.4c-.33 2.52 2.38 3.66 2.38 3.66s-1.63 4.28-3.31 2.83zM13.03 5.48c-.68 1.14-2.12 1.83-3.4 1.57-.27-1.39.46-2.91 1.6-3.87.67-.57 1.82-.96 2.94-.71.18 1.76-1.14 3.01-1.14 3.01z"></path>
</svg>
                    Apple
                </button>
</div>
</main>
<!-- Footer -->
<footer class="p-6 text-center mt-auto">
<p class="text-gray-500 text-sm">
                Don't have an account? 
                <a class="text-primary font-semibold hover:text-primary-dark transition-colors" href="#">Sign up</a>
</p>
</footer>
</div>
</body></html>

<!-- Dashboard Dark Mode -->
<!DOCTYPE html>

<html class="dark" lang="en"><head>
<meta charset="utf-8"/>
<meta content="width=device-width, initial-scale=1.0" name="viewport"/>
<title>Language Tutor Dashboard</title>
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&amp;display=swap" rel="stylesheet"/>
<link href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:wght,FILL@100..700,0..1&amp;display=swap" rel="stylesheet"/>
<link href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:wght,FILL@100..700,0..1&amp;display=swap" rel="stylesheet"/>
<script src="https://cdn.tailwindcss.com?plugins=forms,container-queries"></script>
<script>
        tailwind.config = {
            darkMode: "class",
            theme: {
                extend: {
                    colors: {
                        "primary": "#ff6a00",
                        "primary-content": "#ffffff",
                        "background-light": "#f8f7f5",
                        "background-dark": "#181410", // Very deep charcoal/brown-black
                        "surface-dark": "#2a241f", // Slightly lighter for cards
                        "surface-highlight": "#3d342d", // Even lighter for interactions
                        "text-primary": "#f2f2f2",
                        "text-secondary": "#a8a29e",
                    },
                    fontFamily: {
                        "display": ["Inter", "sans-serif"]
                    },
                    borderRadius: { "DEFAULT": "0.25rem", "lg": "0.5rem", "xl": "0.75rem", "full": "9999px" },
                },
            },
        }
    </script>
<style>
    body {
      min-height: max(884px, 100dvh);
    }
  </style>
  </head>
<body class="bg-background-dark text-text-primary font-display min-h-screen flex flex-col overflow-x-hidden antialiased selection:bg-primary selection:text-white">
<!-- Main Content Area -->
<div class="flex-1 flex flex-col w-full max-w-md mx-auto relative pb-24">
<!-- Header -->
<header class="flex items-center justify-between px-6 pt-8 pb-4 bg-background-dark sticky top-0 z-10">
<div class="flex flex-col gap-0.5">
<p class="text-text-secondary text-sm font-medium tracking-wide uppercase">Tuesday, Oct 24</p>
<h1 class="text-2xl font-bold tracking-tight text-white">Hola, Alex! 👋</h1>
</div>
<div class="flex items-center gap-3">
<button class="relative p-2 rounded-full text-text-secondary hover:text-white hover:bg-surface-dark transition-colors">
<span class="material-symbols-outlined text-[24px]">notifications</span>
<span class="absolute top-2 right-2 w-2 h-2 bg-primary rounded-full border-2 border-background-dark"></span>
</button>
<div class="h-10 w-10 rounded-full bg-surface-dark border-2 border-surface-highlight overflow-hidden relative" data-alt="User profile avatar showing a smiling person">
<img alt="User Profile" class="w-full h-full object-cover" src="https://lh3.googleusercontent.com/aida-public/AB6AXuCO1mgadmQP8s94UlYpGo3wK70FCb_AL5BIliw86XmrxOvh8Bb6gfD7r3vZH4HULIPo-iZnyDyH32pDx2WrFkJ9vSOHOws0gt9zdD-GhmO2Xq2PE27k5CM4keKKF4eHkxBcXt_uP8ch2o08lndqhAE4jy5dBM4_Js2TRXjiv9QD8KwM7e9X5-PQpau_XsCwWDeieG0Il4W6V1NfHOxvIz8eCv95SjIv60QUVCsS4wcb7h3QXKdQhTtzu3foJcOFP71trrdaL-oIoGY"/>
</div>
</div>
</header>
<!-- Stats Row -->
<div class="px-4 py-2 grid grid-cols-2 gap-3">
<!-- Streak Card -->
<div class="bg-surface-dark rounded-xl p-4 flex items-center justify-between shadow-lg border border-surface-highlight/20 group">
<div class="flex flex-col">
<span class="text-text-secondary text-xs font-medium uppercase tracking-wider">Streak</span>
<span class="text-white text-2xl font-bold">12 Days</span>
</div>
<div class="h-10 w-10 rounded-full bg-primary/20 flex items-center justify-center text-primary group-hover:scale-110 transition-transform duration-300">
<span class="material-symbols-outlined text-[24px] fill-current">local_fire_department</span>
</div>
</div>
<!-- Daily Goal Card -->
<div class="bg-surface-dark rounded-xl p-4 flex items-center justify-between shadow-lg border border-surface-highlight/20">
<div class="flex flex-col">
<span class="text-text-secondary text-xs font-medium uppercase tracking-wider">Daily Goal</span>
<span class="text-white text-2xl font-bold">15<span class="text-base text-text-secondary font-medium">/20m</span></span>
</div>
<div class="relative h-10 w-10 flex items-center justify-center">
<!-- Circular Progress Indicator simulation -->
<svg class="w-full h-full transform -rotate-90" viewbox="0 0 36 36">
<path class="text-surface-highlight" d="M18 2.0845 a 15.9155 15.9155 0 0 1 0 31.831 a 15.9155 15.9155 0 0 1 0 -31.831" fill="none" stroke="currentColor" stroke-width="4"></path>
<path class="text-primary drop-shadow-[0_0_4px_rgba(255,106,0,0.5)]" d="M18 2.0845 a 15.9155 15.9155 0 0 1 0 31.831 a 15.9155 15.9155 0 0 1 0 -31.831" fill="none" stroke="currentColor" stroke-dasharray="75, 100" stroke-linecap="round" stroke-width="4"></path>
</svg>
<span class="material-symbols-outlined absolute text-[16px] text-primary">timer</span>
</div>
</div>
</div>
<!-- Continue Lesson Section -->
<div class="px-4 py-6">
<div class="flex items-center justify-between mb-3 px-1">
<h2 class="text-lg font-bold text-white tracking-tight">Continue Learning</h2>
<button class="text-primary text-sm font-medium hover:text-orange-400 transition-colors">View All</button>
</div>
<div class="bg-surface-dark rounded-2xl overflow-hidden shadow-xl border border-surface-highlight/30">
<div class="h-40 w-full relative bg-gray-800" data-alt="Abstract cozy cafe setting with warm lighting for coffee ordering lesson">
<div class="absolute inset-0 bg-gradient-to-t from-surface-dark to-transparent z-10"></div>
<img alt="Coffee Shop" class="w-full h-full object-cover opacity-80 mix-blend-overlay" src="https://lh3.googleusercontent.com/aida-public/AB6AXuDwJnV0wUYKVYC6iQt4gefWGr_5j4vvFn2RGVvSOr5ds0qFxwLEyaSrkwdjkUH1rd5iUU2RU4xOhSpiSe0SjsPq1ayrPXNV1XX0V5R6sU5P2cYdtfmaVK8OweUYVn5bvj3iu5CUdGcLHfSL0l0Q0-FotyinF2ZjBqwFbCyCSA7LJM7-gkaG1SPRZCAJTJ-9xi-C-vTR2emgVh4nrQECXrteuY7fWt3Y8ZL9DdA85yOpa1S4jlgYY5dO5rxBt8t2G_OrrSdXWGI5H1M"/>
<div class="absolute bottom-4 left-4 z-20">
<span class="bg-primary/90 text-white text-[10px] font-bold px-2 py-1 rounded uppercase tracking-wider mb-2 inline-block shadow-sm">Unit 3</span>
<h3 class="text-2xl font-bold text-white leading-tight shadow-black drop-shadow-md">Ordering Coffee</h3>
<p class="text-gray-300 text-sm font-medium mt-0.5">Conversation Practice</p>
</div>
</div>
<div class="p-5">
<div class="flex items-center justify-between mb-2">
<span class="text-text-secondary text-xs font-semibold uppercase tracking-wide">Progress</span>
<span class="text-white text-xs font-bold">60%</span>
</div>
<div class="w-full bg-surface-highlight rounded-full h-2 mb-6">
<div class="bg-primary h-2 rounded-full shadow-[0_0_8px_rgba(255,106,0,0.6)]" style="width: 60%"></div>
</div>
<button class="w-full bg-primary hover:bg-orange-500 active:bg-orange-600 text-white font-bold py-3.5 px-4 rounded-xl flex items-center justify-center gap-2 transition-all shadow-lg shadow-primary/20">
<span class="material-symbols-outlined text-[20px]">play_arrow</span>
                        Continue Lesson
                    </button>
</div>
</div>
</div>
<!-- Recommended / For You -->
<div class="px-4 pb-4">
<h2 class="text-lg font-bold text-white mb-3 px-1 tracking-tight">For You</h2>
<div class="grid gap-3">
<!-- List Item 1 -->
<div class="bg-surface-dark p-3 rounded-xl flex items-center gap-4 border border-surface-highlight/20 hover:border-surface-highlight transition-colors cursor-pointer">
<div class="h-12 w-12 rounded-lg bg-emerald-500/10 flex items-center justify-center shrink-0">
<span class="material-symbols-outlined text-emerald-500 text-[24px]">translate</span>
</div>
<div class="flex-1">
<h4 class="text-white font-semibold text-sm">Vocabulary Review</h4>
<p class="text-text-secondary text-xs">50 words due for review</p>
</div>
<span class="material-symbols-outlined text-text-secondary text-[20px]">chevron_right</span>
</div>
<!-- List Item 2 -->
<div class="bg-surface-dark p-3 rounded-xl flex items-center gap-4 border border-surface-highlight/20 hover:border-surface-highlight transition-colors cursor-pointer">
<div class="h-12 w-12 rounded-lg bg-blue-500/10 flex items-center justify-center shrink-0">
<span class="material-symbols-outlined text-blue-500 text-[24px]">headphones</span>
</div>
<div class="flex-1">
<h4 class="text-white font-semibold text-sm">Listening Challenge</h4>
<p class="text-text-secondary text-xs">Podcast: Daily News</p>
</div>
<span class="material-symbols-outlined text-text-secondary text-[20px]">chevron_right</span>
</div>
</div>
</div>
</div>
<!-- Bottom Navigation -->
<div class="fixed bottom-0 left-0 right-0 bg-surface-dark/95 backdrop-blur-md border-t border-surface-highlight pb-6 pt-3 px-6 z-50">
<div class="max-w-md mx-auto flex justify-between items-center">
<a class="flex flex-col items-center gap-1 group" href="#">
<div class="text-primary bg-primary/10 px-4 py-1 rounded-full transition-colors">
<span class="material-symbols-outlined text-[24px] fill-current">home</span>
</div>
<span class="text-primary text-[10px] font-semibold">Home</span>
</a>
<a class="flex flex-col items-center gap-1 group" href="#">
<div class="text-text-secondary group-hover:text-primary transition-colors px-4 py-1">
<span class="material-symbols-outlined text-[24px]">explore</span>
</div>
<span class="text-text-secondary text-[10px] font-medium group-hover:text-primary transition-colors">Explore</span>
</a>
<a class="flex flex-col items-center gap-1 group" href="#">
<div class="text-text-secondary group-hover:text-primary transition-colors px-4 py-1">
<span class="material-symbols-outlined text-[24px]">chat_bubble</span>
</div>
<span class="text-text-secondary text-[10px] font-medium group-hover:text-primary transition-colors">Chat</span>
</a>
<a class="flex flex-col items-center gap-1 group" href="#">
<div class="text-text-secondary group-hover:text-primary transition-colors px-4 py-1">
<span class="material-symbols-outlined text-[24px]">person</span>
</div>
<span class="text-text-secondary text-[10px] font-medium group-hover:text-primary transition-colors">Profile</span>
</a>
</div>
</div>
</body></html>