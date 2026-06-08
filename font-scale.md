# Quy tắc Scale Kích thước trong React Native

Để ứng dụng hiển thị nhất quán trên nhiều kích thước màn hình khác nhau (từ màn hình nhỏ gọn đến Tablet/iPad), dự án áp dụng cơ chế **Fluid Scaling (Co giãn theo tỷ lệ màn hình)** kết hợp với **Max Cap (Giới hạn kích thước tối đa)**.

### 1. Cơ chế Fluid Scaling (Co giãn theo tỷ lệ màn hình)

Thay vì sử dụng các giá trị kích thước (font chữ, padding, margin...) cố định, chúng ta tính toán kích thước dựa trên tỷ lệ chiều rộng màn hình thiết bị so với màn hình thiết kế gốc.

- **Base Design (Bản thiết kế chuẩn):** Lấy mốc thiết kế với chiều rộng màn hình là **390px** (tương đương iPhone 13/14).
- **Công thức cơ bản:** `Kích thước thực tế = (Kích thước trên design / 390) * Chiều rộng màn hình thiết bị`.

### 2. Giới hạn tỷ lệ phóng to (Max Cap) ở 430px

Nếu chỉ scale theo chiều rộng màn hình, các thành phần trên thiết bị màn hình lớn (như iPad) sẽ bị phóng to quá mức, làm mất thẩm mỹ. Để giải quyết, chúng ta sẽ "khóa" chiều rộng tính toán tối đa ở mức `430px` (tương đương chiều rộng iPhone Pro Max).

**Quy tắc áp dụng:**

- **Trên điện thoại (width ≤ 430px):** Kích thước co giãn hoàn toàn tự nhiên theo đúng tỷ lệ màn hình.
- **Trên màn hình lớn (Tablet, iPad, width > 430px):** Chiều rộng tính toán bị giới hạn ở 430px. Nghĩa là dù thiết bị có to đến mấy, các component cũng chỉ lớn tối đa bằng kích thước hiển thị trên iPhone Pro Max, giúp giữ nguyên tỷ lệ thiết kế, không bị vỡ hoặc phình to quá mức.

### 3. Tối ưu Rendering cho từng Hệ điều hành (iOS vs Android)

Cách React Native render text trên iOS và Android có sự khác biệt, do đó kết quả tính toán cần được làm tròn phù hợp:

- **Trên iOS:** Hệ điều hành xử lý số thập phân rất tốt. Ta làm tròn đến 2 chữ số thập phân để đảm bảo kích thước mượt mà, chính xác và không bị sai lệch khoảng cách nhỏ.
- **Trên Android:** Engine render của Android thường gây ra hiện tượng mờ chữ, nhòe hoặc cắt viền nếu font size hay line height là số thập phân. Do đó, bắt buộc phải làm tròn thành số nguyên (`Math.ceil`) để text luôn sắc nét trên Android.

### 4. Implementation (Code Tham khảo)

Dưới đây là hàm utility mẫu có thể dùng ở bất kỳ dự án React Native nào (áp dụng được cho cả font chữ và layout component):

```typescript
import { Dimensions, Platform } from 'react-native';

const { width: SCREEN_WIDTH } = Dimensions.get('window');

// 1. Chiều rộng của bản thiết kế chuẩn (VD: Figma 390px)
const BASE_WIDTH = 390;

// 2. Giới hạn chiều rộng tối đa (Max Cap - VD: 430px)
const MAX_WIDTH = 430;

/**
 * Hàm tính toán kích thước tương thích các màn hình
 * @param size Kích thước đo được trên bản thiết kế
 */
export const scale = (size: number): number => {
  // Khóa chiều rộng tối đa ở MAX_WIDTH
  const calcWidth = Math.min(SCREEN_WIDTH, MAX_WIDTH);

  // Tính tỷ lệ kích thước mới
  const rawSize = (size / BASE_WIDTH) * calcWidth;

  // Xử lý làm tròn riêng cho iOS và Android
  return Platform.OS === 'ios'
    ? Number(rawSize.toFixed(2))
    : Math.round(rawSize);
};

// Có thể tạo alias riêng cho font chữ nếu cần
export const fontScale = scale;
```

### 5. Quy tắc Scale Khoảng cách (Spacing)

Bên cạnh font chữ và kích thước tổng thể (width, height), các khoảng trống như `margin`, `padding`, `gap` cũng cần được scale đồng bộ để giữ nguyên tỷ lệ cấu trúc giao diện.

**Cơ chế Base Unit (Đơn vị cơ sở):**
Hệ thống thiết kế (Design System) hiện đại thường sử dụng một đơn vị khoảng cách cơ sở (Base Unit), ví dụ phổ biến nhất là **4px** (hoặc 8px). 
Mọi khoảng cách sẽ là bội số của đơn vị cơ sở này (VD: `spacing(1)` = 4px, `spacing(4)` = 16px).

Để khoảng cách co giãn đồng đều theo màn hình thiết bị, chúng ta sẽ áp dụng hàm `scale` ở trên trực tiếp cho Base Unit.

**Implementation (Code Tham khảo Spacing):**

```typescript
// 3. Định nghĩa đơn vị cơ sở chuẩn trên bản thiết kế (VD: 4px)
const BASE_SPACING = 4;

/**
 * Hàm tính toán khoảng cách (margin, padding, gap, borderRadius...)
 * @param multiplier Hệ số nhân (Ví dụ: truyền 4 sẽ tính toán dựa trên 16px (4*4) của màn 390px)
 */
export const spacing = (multiplier: number): number => {
  // Tính kích thước gốc trên design
  const designSize = BASE_SPACING * multiplier;
  
  // Dùng hàm scale đã viết ở trên để co giãn khoảng cách này
  return scale(designSize);
};
```

### 6. Ví dụ cách sử dụng (Usage Example)

```tsx
import React from 'react';
import { View, Text, StyleSheet } from 'react-native';
import { scale, fontScale, spacing } from './scale'; // File utility vừa tạo

const MyComponent = () => {
  return (
    <View style={styles.card}>
      <Text style={styles.title}>Thẻ thông tin</Text>
      <Text style={styles.desc}>Nội dung thẻ được scale chuẩn trên mọi thiết bị.</Text>
    </View>
  );
};

const styles = StyleSheet.create({
  card: {
    // Chiều rộng tổng 340 trên design 390px, tự động scale
    width: scale(340), 
    
    // Padding = 4 * 4 = 16px (tự động scale)
    padding: spacing(4), 
    
    // Bo góc = 4 * 3 = 12px (tự động scale)
    borderRadius: spacing(3), 
    
    backgroundColor: '#fff',
  },
  title: {
    // Font chữ 18px (tự động scale)
    fontSize: fontScale(18),
    fontWeight: 'bold',
    
    // Margin bottom = 4 * 2 = 8px
    marginBottom: spacing(2),
  },
  desc: {
    // Font chữ 14px (tự động scale)
    fontSize: fontScale(14),
    lineHeight: fontScale(20), // Line height cũng cần scale
  }
});
```
