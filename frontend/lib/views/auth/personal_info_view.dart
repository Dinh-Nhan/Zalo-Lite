import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:frontend/component/loading_dialog.dart';
import 'package:frontend/component/success_dialog.dart';
import 'package:frontend/config/app_colors.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class PersonalInfoView extends StatefulWidget {
  const PersonalInfoView({super.key});

  @override
  State<PersonalInfoView> createState() => _PersonalInfoViewState();
}

class _PersonalInfoViewState extends State<PersonalInfoView> {
  final _formKey = GlobalKey<FormState>();
  
  final TextEditingController _birthController = TextEditingController();
  final TextEditingController _genderController = TextEditingController();

  DateTime _tempDate = DateTime(2000, 1, 1);
  bool _isButtonEnabled = false;

  // Cập nhật trạng thái nút Tiếp tục
  void _updateButtonState() {
    setState(() {
      _isButtonEnabled = _birthController.text.isNotEmpty && 
                         _genderController.text.isNotEmpty;
    });
  }

  // 1. Hiển thị chọn ngày sinh (Kiểu vòng quay Zalo)
  void _showDatePicker() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 350,
          color: Colors.white,
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text("Chọn ngày sinh", 
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: DateTime(2000, 1, 1),
                  onDateTimeChanged: (DateTime newDate) {
                    _tempDate = newDate;
                  },
                ),
              ),
              const Text("Bạn cần đủ 14 tuổi để sử dụng Zalo", 
                style: TextStyle(color: Colors.grey, fontSize: 13)),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue, shape: const StadiumBorder()),
                    onPressed: () {
                      setState(() {
                        _birthController.text = DateFormat('dd/MM/yyyy').format(_tempDate);
                      });
                      _updateButtonState();
                      Navigator.pop(context);
                    },
                    child: const Text("Chọn", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              )
            ],
          ),
        );
      },
    );
  }

  // 2. Hiển thị chọn giới tính
  void _showGenderPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Chọn giới tính", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              _genderOption("Nam"),
              _genderOption("Nữ"),
              _genderOption("Không chia sẻ"),
            ],
          ),
        );
      },
    );
  }

  Widget _genderOption(String label) {
    return ListTile(
      title: Center(child: Text(label, style: const TextStyle(fontSize: 16))),
      onTap: () {
        setState(() {
          _genderController.text = label;
        });
        _updateButtonState();
        Navigator.pop(context);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black), onPressed: () => context.go('/enter-name')),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const Text("Thêm thông tin cá nhân", 
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 30),
              
              // Field Ngày sinh
              TextFormField(
                controller: _birthController,
                readOnly: true,
                onTap: _showDatePicker,
                decoration: InputDecoration(
                  hintText: "Sinh nhật",
                  suffixIcon: const Icon(Icons.calendar_today_outlined, size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 20),

              // Field Giới tính
              TextFormField(
                controller: _genderController,
                readOnly: true,
                onTap: _showGenderPicker,
                decoration: InputDecoration(
                  hintText: "Giới tính",
                  suffixIcon: const Icon(Icons.keyboard_arrow_down, size: 24),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(12)),
                ),
              ),

              const Spacer(),

              // Nút Tiếp tục
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isButtonEnabled 
                  ? () async {
                      // 1. Hiện loading đang xử lý
                      LoadingDialog.show(context);
                      
                      // Giả lập gọi API tạo tài khoản
                      await Future.delayed(const Duration(seconds: 2));
                      
                      if (!mounted) return;
                      LoadingDialog.hide(context);

                      // 2. Hiện thông báo thành công
                      SuccessDialog.show(context, () {
                        // Hành động chuyển vào tài khoản (vào Home)
                        context.go('/update-avatar'); 
                      });
                    }
                  : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    disabledBackgroundColor: Colors.grey.shade200,
                    shape: const StadiumBorder(),
                    elevation: 0,
                  ),
                  child: Text("Tiếp tục", 
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, 
                    color: _isButtonEnabled ? Colors.white : Colors.grey.shade400)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}