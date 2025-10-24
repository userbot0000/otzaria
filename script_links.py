import re
import os
import tkinter as tk
from tkinter import ttk, filedialog, messagebox, scrolledtext
import threading
from pathlib import Path

def create_talmud_links(text):
    """יוצר קישורים לטקסטים תלמודיים לפי הדפוסים הספציפיים בלבד"""
    
    # רשימת מסכתות בסיסית
    tractates = ['ברכות', 'שבת', 'עירובין', 'פסחים', 'יומא', 'סוכה', 'ביצה', 
                'ראש השנה', 'תענית', 'מגילה', 'מועד קטן', 'חגיגה', 'יבמות', 
                'כתובות', 'נדרים', 'נזיר', 'סוטה', 'גיטין', 'קידושין', 
                'בבא קמא', 'בבא מציעא', 'בבא בתרא', 'סנהדרין', 'מכות', 
                'שבועות', 'עבודה זרה', 'הוריות', 'זבחים', 'מנחות', 'חולין', 
                'בכורות', 'ערכין', 'תמורה', 'כריתות', 'מעילה', 'נדה',
                'ב"ק', 'ב"מ', 'ב"ב', 'ר"ה', 'מ"ק', 'ע"ז']
    
    # מיפוי קיצורים לשמות מלאים
    abbreviations = {
        'ב"ק': 'בבא קמא', 'ב"מ': 'בבא מציעא', 'ב"ב': 'בבא בתרא',
        'ר"ה': 'ראש השנה', 'מ"ק': 'מועד קטן', 'ע"ז': 'עבודה זרה'
    }
    
    def clean_tractate(name):
        """מנקה קידומות ומחזיר שם מלא"""
        # הסרת קידומות
        for prefix in ['ב', 'ד', 'ו', 'מ', 'ש', 'כ', 'ל']:
            if name.startswith(prefix) and name[1:] in tractates:
                name = name[1:]
                break
        # החזרת שם מלא אם זה קיצור
        return abbreviations.get(name, name)
    
    def is_inside_link(text, match_start, match_end):
        """בודק אם המתאמה נמצאת בתוך תג קישור קיים"""
        # מחפש תג פתיחה לפני המתאמה
        before_text = text[:match_start]
        after_text = text[match_end:]
        
        # מחפש את התג <a> הקרוב ביותר לפני המתאמה
        last_a_open = before_text.rfind('<a ')
        last_a_close = before_text.rfind('</a>')
        
        # אם יש תג פתיחה אחרי תג סגירה, זה אומר שאנחנו בתוך קישור
        if last_a_open > last_a_close:
            # בודק אם יש תג סגירה אחרי המתאמה
            next_a_close = after_text.find('</a>')
            if next_a_close != -1:
                return True
        
        return False
    
    # יצירת רשימה של כל האפשרויות (עם קידומות)
    all_options = []
    for tractate in tractates:
        all_options.append(tractate)
        for prefix in ['ב', 'ד', 'ו', 'מ', 'ש', 'כ', 'ל']:
            all_options.append(prefix + tractate)
    
    # מיון לפי אורך (הארוכים קודם)
    all_options.sort(key=len, reverse=True)
    tractate_pattern = '|'.join(re.escape(opt) for opt in all_options)
    
    # דפוס פשוט למספרי דפים - מספרים ערביים או אותיות עבריות עם גרש/גרשיים
    page_pattern = r'[א-ת\d"\':]+'
    
    result = text
    
    def safe_replace(pattern, replace_func, text):
        """מחליף רק אם המתאמה לא נמצאת בתוך קישור קיים"""
        matches = list(re.finditer(pattern, text))
        # עובר מהסוף להתחלה כדי לא לשבש את האינדקסים
        for match in reversed(matches):
            if not is_inside_link(text, match.start(), match.end()):
                replacement = replace_func(match)
                text = text[:match.start()] + replacement + text[match.end():]
        return text
    
    # דפוס 1: (מסכת מספר,עמוד)
    pattern = rf'\(({tractate_pattern})\s+({page_pattern}),([אב])\)'
    def replace_func(m):
        tractate = clean_tractate(m.group(1))
        page = m.group(2)
        side = m.group(3)
        return f'<a href="book://{tractate}#דף {page}#ע"{side}">{m.group(0)}</a>'
    result = safe_replace(pattern, replace_func, result)
    
    # דפוס 2: מסכת (מספר,עמוד) - סוגריים אחרי רווח
    pattern = rf'(?<!\w)({tractate_pattern})\s+\(({page_pattern}),([אב])\)'
    def replace_func(m):
        tractate = clean_tractate(m.group(1))
        page = m.group(2)
        side = m.group(3)
        return f'<a href="book://{tractate}#דף {page}#ע"{side}">{m.group(0)}</a>'
    result = safe_replace(pattern, replace_func, result)
    
    # דפוס 3: מסכת[דף עמוד]
    pattern = rf'(?<!\w)({tractate_pattern})\[דף\s+({page_pattern})\]'
    def replace_func(m):
        tractate = clean_tractate(m.group(1))
        page = m.group(2)
        return f'<a href="book://{tractate}#דף {page}">{m.group(0)}</a>'
    result = safe_replace(pattern, replace_func, result)
    
    # דפוס 4: מסכת דף מספר ע"א/ע"ב (הארוך ביותר - קודם!)
    pattern = rf'(?<!\w)({tractate_pattern})\s+דף\s+({page_pattern})\s+(ע"[אב])(?!\w)'
    def replace_func(m):
        tractate = clean_tractate(m.group(1))
        page = m.group(2)
        side = m.group(3)
        return f'<a href="book://{tractate}#דף {page}#{side}">{m.group(0)}</a>'
    result = safe_replace(pattern, replace_func, result)
    
    # דפוס חדש: מסכת דף ע"א/ע"ב (בלי מספר דף ספציפי)
    pattern = rf'(?<!\w)({tractate_pattern})\s+דף\s+(ע"[אב])(?!\w)'
    def replace_func(m):
        tractate = clean_tractate(m.group(1))
        side = m.group(2)
        return f'<a href="book://{tractate}#{side}">{m.group(0)}</a>'
    result = safe_replace(pattern, replace_func, result)
    
    # דפוס 7: מסכת מספר ע"א/ע"ב (בלי "דף") - לפני דפוס 5!
    pattern = rf'(?<!\w)({tractate_pattern})\s+({page_pattern})\s+(ע"[אב])(?!\w)'
    def replace_func(m):
        tractate = clean_tractate(m.group(1))
        page = m.group(2)
        side = m.group(3)
        return f'<a href="book://{tractate}#דף {page}#{side}">{m.group(0)}</a>'
    result = safe_replace(pattern, replace_func, result)
    
    # דפוס 5: מסכת דף מספר אות (כמו "נדה דף ב א")
    pattern = rf'(?<!\w)({tractate_pattern})\s+דף\s+({page_pattern})\s+([אב])(?!\s*ע")(?!\w)'
    def replace_func(m):
        tractate = clean_tractate(m.group(1))
        page = m.group(2)
        side = m.group(3)
        return f'<a href="book://{tractate}#דף {page}#ע"{side}">{m.group(0)}</a>'
    result = safe_replace(pattern, replace_func, result)
    
    # דפוס 8: מסכת מספר' עמוד'
    pattern = rf'(?<!\w)({tractate_pattern})\s+({page_pattern})\'\s*([אב])\'(?!\w)'
    def replace_func(m):
        tractate = clean_tractate(m.group(1))
        page = m.group(2)
        side = m.group(3)
        return f'<a href="book://{tractate}#דף {page}#ע"{side}">{m.group(0)}</a>'
    result = safe_replace(pattern, replace_func, result)
    
    # דפוס 6: מסכת דף מספר (בלי עמוד ספציפי) - אחרון!
    pattern = rf'(?<!\w)({tractate_pattern})\s+דף\s+({page_pattern})(?!\s+[אבע"])(?!\w)'
    def replace_func(m):
        tractate = clean_tractate(m.group(1))
        page = m.group(2)
        return f'<a href="book://{tractate}#דף {page}">{m.group(0)}</a>'
    result = safe_replace(pattern, replace_func, result)
    
    # דפוס 9: מסכת מספר. (נקודה אחת)
    pattern = rf'(?<!\w)({tractate_pattern})\s+({page_pattern})\.(?!\w)'
    def replace_func(m):
        tractate = clean_tractate(m.group(1))
        page = m.group(2)
        return f'<a href="book://{tractate}#דף {page}.">{m.group(0)}</a>'
    result = safe_replace(pattern, replace_func, result)
    
    # דפוס 10: מסכת דף מספר: (נקודותיים)
    pattern = rf'(?<!\w)({tractate_pattern})\s+דף\s+({page_pattern}):(?!\w)'
    def replace_func(m):
        tractate = clean_tractate(m.group(1))
        page = m.group(2)
        return f'<a href="book://{tractate}#דף {page}:">{m.group(0)}</a>'
    result = safe_replace(pattern, replace_func, result)
    
    return result


class TalmudLinkerGUI:
    def __init__(self, root):
        self.root = root
        self.root.title("מתקן קישורי תלמוד")
        self.root.geometry("800x600")
        self.root.configure(bg='#f0f0f0')
        
        # משתנים
        self.selected_folder = tk.StringVar()
        self.file_extensions = tk.StringVar(value=".txt,.html,.md")
        self.include_subfolders = tk.BooleanVar(value=True)
        self.create_backup = tk.BooleanVar(value=True)
        self.processed_files = 0
        self.total_files = 0
        
        self.setup_ui()
        
    def setup_ui(self):
        # כותרת
        title_frame = tk.Frame(self.root, bg='#2c3e50', height=60)
        title_frame.pack(fill='x', padx=10, pady=(10, 0))
        title_frame.pack_propagate(False)
        
        title_label = tk.Label(title_frame, text="מתקן קישורי תלמוד", 
                              font=('Arial', 18, 'bold'), 
                              fg='white', bg='#2c3e50')
        title_label.pack(expand=True)
        
        # מסגרת ראשית
        main_frame = tk.Frame(self.root, bg='#f0f0f0')
        main_frame.pack(fill='both', expand=True, padx=10, pady=10)
        
        # בחירת תיקייה
        folder_frame = tk.LabelFrame(main_frame, text="בחירת תיקייה", 
                                   font=('Arial', 12, 'bold'), 
                                   bg='#f0f0f0', fg='#2c3e50')
        folder_frame.pack(fill='x', pady=(0, 10))
        
        folder_inner = tk.Frame(folder_frame, bg='#f0f0f0')
        folder_inner.pack(fill='x', padx=10, pady=10)
        
        self.folder_entry = tk.Entry(folder_inner, textvariable=self.selected_folder, 
                                   font=('Arial', 10), width=50)
        self.folder_entry.pack(side='left', fill='x', expand=True)
        
        browse_btn = tk.Button(folder_inner, text="עיון...", 
                             command=self.browse_folder,
                             bg='#3498db', fg='white', 
                             font=('Arial', 10, 'bold'),
                             relief='flat', padx=20)
        browse_btn.pack(side='right', padx=(10, 0))
        
        # הגדרות
        settings_frame = tk.LabelFrame(main_frame, text="הגדרות", 
                                     font=('Arial', 12, 'bold'), 
                                     bg='#f0f0f0', fg='#2c3e50')
        settings_frame.pack(fill='x', pady=(0, 10))
        
        settings_inner = tk.Frame(settings_frame, bg='#f0f0f0')
        settings_inner.pack(fill='x', padx=10, pady=10)
        
        # סוגי קבצים
        ext_frame = tk.Frame(settings_inner, bg='#f0f0f0')
        ext_frame.pack(fill='x', pady=(0, 10))
        
        tk.Label(ext_frame, text="סוגי קבצים:", 
                font=('Arial', 10), bg='#f0f0f0').pack(side='left')
        
        ext_entry = tk.Entry(ext_frame, textvariable=self.file_extensions, 
                           font=('Arial', 10), width=30)
        ext_entry.pack(side='left', padx=(10, 0))
        
        tk.Label(ext_frame, text="(מופרד בפסיקים)", 
                font=('Arial', 9), fg='gray', bg='#f0f0f0').pack(side='left', padx=(5, 0))
        
        # תיבות סימון
        checkbox_frame = tk.Frame(settings_inner, bg='#f0f0f0')
        checkbox_frame.pack(fill='x')
        
        subfolder_cb = tk.Checkbutton(checkbox_frame, text="כלול תת-תיקיות", 
                                    variable=self.include_subfolders,
                                    font=('Arial', 10), bg='#f0f0f0')
        subfolder_cb.pack(side='left')
        
        backup_cb = tk.Checkbutton(checkbox_frame, text="צור גיבוי לפני שינוי", 
                                 variable=self.create_backup,
                                 font=('Arial', 10), bg='#f0f0f0')
        backup_cb.pack(side='left', padx=(20, 0))
        
        # כפתורים
        button_frame = tk.Frame(main_frame, bg='#f0f0f0')
        button_frame.pack(fill='x', pady=(0, 10))
        
        self.process_btn = tk.Button(button_frame, text="התחל עיבוד", 
                                   command=self.start_processing,
                                   bg='#27ae60', fg='white', 
                                   font=('Arial', 12, 'bold'),
                                   relief='flat', padx=30, pady=10)
        self.process_btn.pack(side='left')
        
        self.stop_btn = tk.Button(button_frame, text="עצור", 
                                command=self.stop_processing,
                                bg='#e74c3c', fg='white', 
                                font=('Arial', 12, 'bold'),
                                relief='flat', padx=30, pady=10,
                                state='disabled')
        self.stop_btn.pack(side='left', padx=(10, 0))
        
        # כפתור בדיקה
        test_btn = tk.Button(button_frame, text="בדיקה מהירה", 
                           command=self.quick_test,
                           bg='#f39c12', fg='white', 
                           font=('Arial', 12, 'bold'),
                           relief='flat', padx=30, pady=10)
        test_btn.pack(side='right')
        
        # פס התקדמות
        progress_frame = tk.Frame(main_frame, bg='#f0f0f0')
        progress_frame.pack(fill='x', pady=(0, 10))
        
        self.progress = ttk.Progressbar(progress_frame, mode='determinate')
        self.progress.pack(fill='x', pady=(0, 5))
        
        self.progress_label = tk.Label(progress_frame, text="מוכן לעיבוד", 
                                     font=('Arial', 10), bg='#f0f0f0')
        self.progress_label.pack()
        
        # אזור לוג
        log_frame = tk.LabelFrame(main_frame, text="יומן פעילות", 
                                font=('Arial', 12, 'bold'), 
                                bg='#f0f0f0', fg='#2c3e50')
        log_frame.pack(fill='both', expand=True)
        
        self.log_text = scrolledtext.ScrolledText(log_frame, 
                                                font=('Consolas', 9),
                                                bg='#2c3e50', fg='#ecf0f1',
                                                insertbackground='white')
        self.log_text.pack(fill='both', expand=True, padx=10, pady=10)
        
        # משתנה לעצירת העיבוד
        self.stop_processing_flag = False
        
    def browse_folder(self):
        folder = filedialog.askdirectory(title="בחר תיקייה לעיבוד")
        if folder:
            self.selected_folder.set(folder)
            
    def log_message(self, message):
        self.log_text.insert(tk.END, f"{message}\n")
        self.log_text.see(tk.END)
        self.root.update_idletasks()
        
    def quick_test(self):
        """בדיקה מהירה של הפונקציה"""
        test_text = """נדרים להבא. קידושין לעולם. בכתובות דף ק"א ע"ב וכן בחולין (דף קל"ב ע"א) וכן בברכות דף י ע"א וכן בשבת דף ג. 
        ראה גם במועד קטן י וכן ברכות ג' א'. שבת לא דוחה את החג. בשבת דף ע"א נאמר כך. ברכות דף ג: וכן ברכות דף ה.
        נדה דף ב א וביצה דף כא ע"ב. בנדה ס. ו(שבת ט,א) אבל חגיגה לא מועילה.
        תענית (ט,ב) ומגילה[דף ב] הם דוגמאות נוספות. קידושין דף כ ע"א. נדרים דף ה ע"ב."""
        
        self.log_text.delete(1.0, tk.END)
        self.log_message("בדיקה מהירה:")
        self.log_message("-" * 50)
        self.log_message("טקסט מקורי:")
        self.log_message(test_text)
        self.log_message("-" * 50)
        
        result = create_talmud_links(test_text)
        self.log_message("תוצאה:")
        self.log_message(result)
        
    def get_files_to_process(self):
        if not self.selected_folder.get():
            return []
            
        folder_path = Path(self.selected_folder.get())
        extensions = [ext.strip() for ext in self.file_extensions.get().split(',')]
        files = []
        
        if self.include_subfolders.get():
            for ext in extensions:
                files.extend(folder_path.rglob(f"*{ext}"))
        else:
            for ext in extensions:
                files.extend(folder_path.glob(f"*{ext}"))
                
        return files
        
    def create_backup_file(self, file_path):
        if not self.create_backup.get():
            return
            
        backup_path = file_path.with_suffix(file_path.suffix + '.backup')
        try:
            backup_path.write_text(file_path.read_text(encoding='utf-8'), encoding='utf-8')
            self.log_message(f"נוצר גיבוי: {backup_path.name}")
        except Exception as e:
            self.log_message(f"שגיאה ביצירת גיבוי עבור {file_path.name}: {str(e)}")
            
    def process_file(self, file_path):
        try:
            # קריאת הקובץ
            content = file_path.read_text(encoding='utf-8')
            original_content = content
            
            # יצירת גיבוי
            self.create_backup_file(file_path)
            
            # עיבוד התוכן
            processed_content = create_talmud_links(content)
            
            # בדיקה אם היו שינויים
            if processed_content != original_content:
                # שמירת הקובץ המעובד
                file_path.write_text(processed_content, encoding='utf-8')
                
                # ספירת השינויים
                original_links = original_content.count('<a href="book://')
                new_links = processed_content.count('<a href="book://')
                added_links = new_links - original_links
                
                self.log_message(f"✓ {file_path.name} - נוספו {added_links} קישורים")
                return True
            else:
                self.log_message(f"○ {file_path.name} - לא נדרשו שינויים")
                return False
                
        except Exception as e:
            self.log_message(f"✗ שגיאה בעיבוד {file_path.name}: {str(e)}")
            return False
            
    def start_processing(self):
        if not self.selected_folder.get():
            messagebox.showerror("שגיאה", "אנא בחר תיקייה לעיבוד")
            return
            
        files = self.get_files_to_process()
        if not files:
            messagebox.showwarning("אזהרה", "לא נמצאו קבצים מתאימים לעיבוד")
            return
            
        # הכנת הממשק לעיבוד
        self.process_btn.config(state='disabled')
        self.stop_btn.config(state='normal')
        self.stop_processing_flag = False
        self.processed_files = 0
        self.total_files = len(files)
        
        self.progress.config(maximum=self.total_files)
        self.progress.config(value=0)
        
        self.log_text.delete(1.0, tk.END)
        self.log_message(f"מתחיל עיבוד {self.total_files} קבצים...")
        self.log_message("-" * 50)
        
        # הפעלת העיבוד בחוט נפרד
        thread = threading.Thread(target=self.process_files_thread, args=(files,))
        thread.daemon = True
        thread.start()
        
    def process_files_thread(self, files):
        changed_files = 0
        
        for i, file_path in enumerate(files):
            if self.stop_processing_flag:
                self.log_message("העיבוד הופסק על ידי המשתמש")
                break
                
            self.processed_files = i + 1
            self.root.after(0, self.update_progress)
            
            if self.process_file(file_path):
                changed_files += 1
                
        # סיום העיבוד
        self.root.after(0, self.processing_completed, changed_files)
        
    def update_progress(self):
        self.progress.config(value=self.processed_files)
        self.progress_label.config(text=f"מעבד קובץ {self.processed_files} מתוך {self.total_files}")
        
    def processing_completed(self, changed_files):
        self.process_btn.config(state='normal')
        self.stop_btn.config(state='disabled')
        
        self.log_message("-" * 50)
        self.log_message(f"העיבוד הושלם!")
        self.log_message(f"סה\"כ קבצים שעובדו: {self.processed_files}")
        self.log_message(f"קבצים ששונו: {changed_files}")
        
        self.progress_label.config(text="העיבוד הושלם")
        
        messagebox.showinfo("הושלם", 
                          f"העיבוד הושלם בהצלחה!\n"
                          f"עובדו {self.processed_files} קבצים\n"
                          f"שונו {changed_files} קבצים")
        
    def stop_processing(self):
        self.stop_processing_flag = True
        self.stop_btn.config(state='disabled')


def main():
    root = tk.Tk()
    app = TalmudLinkerGUI(root)
    root.mainloop()


if __name__ == "__main__":
    main()
