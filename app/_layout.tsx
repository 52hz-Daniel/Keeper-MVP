import { Stack } from 'expo-router';
import { StatusBar } from 'expo-status-bar';
import { Platform, View } from 'react-native';
import '../global.css';

export default function RootLayout() {
    return (
        // On web (the hosted demo) render inside a centered phone-sized column.
        <View className="flex-1 bg-black items-center">
            <View
                className="flex-1 w-full bg-midnight"
                style={Platform.OS === 'web' ? { maxWidth: 430 } : undefined}
            >
                <StatusBar style="light" />
                <Stack screenOptions={{
                    headerShown: false,
                    contentStyle: { backgroundColor: '#0F172A' }
                }} />
            </View>
        </View>
    );
}
