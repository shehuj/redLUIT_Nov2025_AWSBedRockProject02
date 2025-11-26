#!/usr/bin/env python3
"""
Automated fix for the 3 remaining markdownlint errors:
1. resume_template.md:85 - Add blank line before heading
2. terraform/README.md:18 - Add 'text' language to code block
3. terraform/README.md:76 - Add 'text' language to code block
"""

import re
import sys
from pathlib import Path


def fix_terraform_readme():
    """Fix terraform/README.md code block language specifications."""
    file_path = Path('terraform/README.md')
    
    if not file_path.exists():
        print(f"❌ File not found: {file_path}")
        return False
    
    with open(file_path, 'r', encoding='utf-8') as f:
        lines = f.readlines()
    
    fixed = False
    
    # Fix line 18 (0-indexed: 17) - Architecture diagram
    if len(lines) > 17 and lines[17].strip() == '```':
        lines[17] = '```text\n'
        print(f"✅ Fixed line 18 in {file_path}")
        fixed = True
    
    # Fix line 76 (0-indexed: 75) - Directory structure
    if len(lines) > 75 and lines[75].strip() == '```':
        lines[75] = '```text\n'
        print(f"✅ Fixed line 76 in {file_path}")
        fixed = True
    
    if fixed:
        with open(file_path, 'w', encoding='utf-8') as f:
            f.writelines(lines)
        print(f"💾 Saved changes to {file_path}")
    else:
        print(f"ℹ️  No changes needed in {file_path}")
    
    return True


def fix_resume_template():
    """Fix resume_template.md blank line before heading."""
    file_path = Path('resume_template.md')
    
    if not file_path.exists():
        print(f"❌ File not found: {file_path}")
        return False
    
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Pattern: text followed by newline, then the heading without a blank line
    # We need to ensure there's a blank line before the heading
    pattern = r'([^\n])\n(#### Infrastructure Automation & CI/CD Excellence)'
    
    if re.search(pattern, content):
        content = re.sub(pattern, r'\1\n\n\2', content)
        
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(content)
        
        print(f"✅ Fixed line 85 in {file_path} - Added blank line before heading")
        print(f"💾 Saved changes to {file_path}")
        return True
    else:
        print(f"ℹ️  No changes needed in {file_path}")
        return True


def main():
    """Main function to fix all markdownlint errors."""
    print("🔧 Fixing markdownlint errors...\n")
    
    success = True
    
    # Fix terraform README
    print("📝 Processing terraform/README.md...")
    if not fix_terraform_readme():
        success = False
    print()
    
    # Fix resume template
    print("📝 Processing resume_template.md...")
    if not fix_resume_template():
        success = False
    print()
    
    if success:
        print("✨ All fixes applied successfully!")
        print("\n📋 Next steps:")
        print("1. Review the changes: git diff")
        print("2. Test locally: pre-commit run markdownlint-cli2 --all-files")
        print("3. Commit: git add . && git commit -m 'Fix markdownlint errors'")
        print("4. Push: git push")
        return 0
    else:
        print("❌ Some fixes failed. Please check the errors above.")
        return 1


if __name__ == '__main__':
    sys.exit(main())